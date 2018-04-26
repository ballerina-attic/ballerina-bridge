// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.


// Packing support is broken in beta13. Will add this once it is fixed.
//package bridge;

import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/config;
import ballerinax/kubernetes;
import ballerina/transactions as txns;
import ballerina/system;


@final string PRIMARY_SERVICE_HOST = config:getAsString("PRIMARY_SERVICE_HOST", default = "127.0.0.1");
@final int PRIMARY_SERVICE_PORT = config:getAsInt("PRIMARY_SERVICE_PORT", default = 8080);
@final string SIDECAR_HOST = config:getAsString("SIDECAR_HOST", default = "127.0.0.1");
@final int SIDECAR_PORT = config:getAsInt("SIDECAR_HOST", default = 9090);

@final string primaryServiceUrl = "http://" + PRIMARY_SERVICE_HOST + ":" + PRIMARY_SERVICE_PORT + "/transaction";

map<TwoPhaseCommitTransaction> participatedTransactions;
string localParticipantId = system:uuid();

type RegistrationRequest {
    string transactionId;
    int transactionBlockId;
    string registerAtUrl;
};

type TwoPhaseCommitTransaction {
    string transactionId;
    string coordinationType = "2pc";
    txns:TransactionState state;
};


@kubernetes :Ingress {
    hostname:"ballerina.bridge.io",
    name:"ballerina-bridge-ingress",
    path:"/"
}

@kubernetes:Service {
    serviceType:"NodePort",
    name:"ballerina-bridge-service"
}
// **** Listener Endpoints ****
endpoint http:Listener bridgeIngressServiceEP {
    port:9090
};

// **** Client Endpoints ****

// Client endpoint that talks to primary service
endpoint http:Client primaryServiceClientEP {
    url: "http://localhost:" + PRIMARY_SERVICE_PORT
};

// Txns : Main car endpoint
endpoint txns:Participant2pcClientEP maincarClient {
    participantURL:primaryServiceUrl,
    timeoutMillis:120000,
    retryConfig:{count:5, interval:5000}
};


@kubernetes:Deployment {
    image: "ballerina/bridge:0.970",
    name: "ballerina-bridge",
    env:{"PRIMARY_SERVICE_PORT":"8080"}
}

@http:ServiceConfig {
    basePath:"/"
}
service<http:Service> BridgeSidecar bind bridgeIngressServiceEP {
    @http:ResourceConfig {
        path:"/*"
    }
    ingressTraffic (endpoint sourceEndpoint, http:Request request) {

        log:printInfo("Ballerina bridge Ingress : " + request.rawPath);
        var res = primaryServiceClientEP -> forward(untaint request.rawPath, request);

        match res {
            http:Response response => {
                _ = sourceEndpoint -> respond(response);
            }
            error err => {
                http:Response response = new;
                response.statusCode = 500;
                response.setPayload(err.message);
                _ = sourceEndpoint -> respond(response);
            }
        }
    }


    // *************** Transactions Handling *******************

    @http:ResourceConfig {
        methods:["POST"],
        body:"regReq"
    }
    register (endpoint conn, http:Request req, RegistrationRequest regReq) {
        http:Response res = new;
        string participantId = localParticipantId;
        string txnId = regReq.transactionId;
        int transactionBlockId = regReq.transactionBlockId;

        //TODO: set the proper protocol
        string protocol = "durable";
        //  "http://" + coordinatorHost + ":" + coordinatorPort + participant2pcCoordinatorBasePath + "/" + transactionBlockId;
        txns:RemoteProtocol[] protocols = [{name:protocol, url:"http://" + SIDECAR_HOST + ":" + SIDECAR_PORT + "/" + transactionBlockId}];
        var result = txns:registerParticipantWithRemoteInitiator(txnId, transactionBlockId,
            regReq.registerAtUrl, protocols);
        match result {
            txns:TransactionContext txnCtx => {
                io:println(txnCtx);
                res.statusCode = http:OK_200;
                res.setPayload("Registration with coordinator successful");
                TwoPhaseCommitTransaction txn = {transactionId:txnId, state:txns:TXN_STATE_ACTIVE};
                participatedTransactions[txnId] = txn;
            }
            error err => {
                res.statusCode = http:INTERNAL_SERVER_ERROR_500;
            }
        }
        var connResult = conn -> respond(res);
        match connResult {
            error err => log:printError("Sending response for register request for transaction " + txnId +
                    " failed", err = err);
            () => log:printInfo("Registered remote participant: " + participantId + " for transaction: " +
                    txnId);
        }
    }


    @http:ResourceConfig {
        methods:["POST"],
        path:"{transactionBlockId}/prepare",
        body:"prepareReq"
    }
    prepare(endpoint conn, http:Request req, int transactionBlockId, txns:PrepareRequest prepareReq) {
        http:Response res = new; res.statusCode = http:INTERNAL_SERVER_ERROR_500;

        string txnId = prepareReq.transactionId;
        log:printInfo("Prepare received for transaction: " + txnId);

        txns:PrepareResponse prepareRes = {};
        if(!participatedTransactions.hasKey(txnId)) {
            res.statusCode = http:NOT_FOUND_404;
            prepareRes.message = txns:TRANSACTION_UNKNOWN;
        } else {
            TwoPhaseCommitTransaction txn = participatedTransactions[txnId];
            // Send the prepare call to the main car and get the response
            string status = prepareMaincar(txn);
            prepareRes.message = status;
            var j = check <json>prepareRes;
            res.statusCode = http:OK_200;
            res.setJsonPayload(j);
        }
        var connResult = conn -> respond(res);
        match connResult {
            error err =>  log:printError("Sending response for prepare request failed", err = err);
            () => {}
        }
    }


    @http:ResourceConfig {
        methods:["POST"],
        path:"{transactionBlockId}/notify",
        body:"notifyReq"
    }
    notify (endpoint conn, http:Request req, int transactionBlockId, txns:NotifyRequest notifyReq) {
        http:Response res = new; res.statusCode = http:INTERNAL_SERVER_ERROR_500;
        string txnId = notifyReq.transactionId;
        log:printInfo("Notify(" + notifyReq.message + ") received for transaction: " + txnId);

        txns:NotifyResponse notifyRes = {};

        if (!participatedTransactions.hasKey(txnId)) {
            res.statusCode = http:NOT_FOUND_404;
            notifyRes.message = txns:TRANSACTION_UNKNOWN;
        } else {
            TwoPhaseCommitTransaction txn = participatedTransactions[txnId];

            if (notifyReq.message == txns:COMMAND_COMMIT) {
                if (txn.state != txns:TXN_STATE_PREPARED) {
                    res.statusCode = http:BAD_REQUEST_400;
                    notifyRes.message = txns:NOTIFY_RESULT_NOT_PREPARED_STR;
                } else {
                    // send the notify(commit) to the maincar
                    var result = notifyMaincar(txnId, notifyReq.message);
                    match result {
                        string => {
                            res.statusCode = http:OK_200;
                            notifyRes.message = txns:NOTIFY_RESULT_COMMITTED_STR;
                        }
                        error => {
                            res.statusCode = http:INTERNAL_SERVER_ERROR_500;
                            log:printError("Committing maincar failed. Transaction:" + txnId);
                            notifyRes.message = txns:NOTIFY_RESULT_FAILED_EOT_STR;
                        }
                    }
                }
            } else if (notifyReq.message == txns:COMMAND_ABORT) {
                // send the notify(abort) to the maincar
                var result = notifyMaincar(txnId, notifyReq.message);
                match result {
                    string => {
                        res.statusCode = http:OK_200;
                        notifyRes.message = txns:NOTIFY_RESULT_ABORTED_STR;
                    }
                    error => {
                        res.statusCode = http:INTERNAL_SERVER_ERROR_500;
                        log:printError("Aborting maincar failed. Transaction:" + txnId);
                        notifyRes.message = txns:NOTIFY_RESULT_FAILED_EOT_STR;
                    }
                }
            }
            removeTransaction(txnId);
            var j = check <json>notifyRes;
            res.setJsonPayload(j);
            var connResult = conn -> respond(res);
            match connResult {
                error err =>  log:printError("Sending response for notify request for transaction " + txnId + " failed", err = err);
                () => {}
            }
        }
    }
}


function prepareMaincar(TwoPhaseCommitTransaction txn) returns string { // return status
    string status;
    string transactionId = txn.transactionId;
    var result = maincarClient-> prepare(transactionId);
    match result {
        error err => {
            log:printError("Maincar failed", err = err);
            removeTransaction(transactionId);
            status = txns:PREPARE_RESULT_ABORTED_STR;
        }
        string str => {
            if (str == txns:PREPARE_RESULT_ABORTED_STR) {
                log:printInfo("Maincar aborted.");
                removeTransaction(transactionId);
            } else if (str == txns:PREPARE_RESULT_COMMITTED_STR) {
                log:printInfo("Maincar committed");
                removeTransaction(transactionId);
            } else if (str == txns:PREPARE_RESULT_READ_ONLY_STR) {
                log:printInfo("Maincar read-only");
                removeTransaction(transactionId);
            } else if (str == txns:PREPARE_RESULT_PREPARED_STR) {
                txn.state = txns:TXN_STATE_PREPARED;
                log:printInfo("Maincar prepared");
            } else {
                string msg = "Invalid maincar status: " + status;
                log:printInfo(msg);
                error e = {message: msg};
                throw e;
            }
            status = str;
        }
    }
    return status;
}

function removeTransaction(string transactionId) {
    if(!participatedTransactions.remove(transactionId)) {
        log:printWarn("Removing transaction: " + transactionId + " failed");
    }
}

function notifyMaincar (string transactionId, string message) returns string|error { //(string status, error err)
    log:printInfo("Notify(" + message + ") maincar");
    var result = maincarClient-> notify(transactionId, message);
    match result {
        error err => {
            log:printError("Maincar replied with an error", err = err);
            return err;
        }
        string notificationStatus => {
            if (notificationStatus == txns:NOTIFY_RESULT_ABORTED_STR) {
                log:printInfo("Maincar aborted");
            } else if (notificationStatus == txns:NOTIFY_RESULT_COMMITTED_STR) {
                log:printInfo("Maincar committed");
            }
            return notificationStatus;
        }
    }
}
