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

//package ballerina.sidecar;

import ballerina/io;
import ballerina/log;
import ballerina/net.http;
import ballerina/transactions.coordinator as coord;
import ballerina/util;

const string sidecarHost = "10.100.1.182"; //TODO: get this from an env var/config API
const int sidecarPort = 33333; //TODO: get this from an env var/config API
const string maincarUrl = "http://10.100.5.131:8080/transaction"; //TODO: get this from an env var/config API

endpoint http:ServiceEndpoint sidecarEP {
    host:sidecarHost,
    port:sidecarPort
};

endpoint coord:Participant2pcClientEP maincarEP {
    participantURL:maincarUrl,
    endpointTimeout:120000,
    retryConfig:{count:5, interval:5000}
};

string mainCarUrl;
map<TwoPhaseCommitTransaction> participatedTransactions = {};
string localParticipantId = util:uuid();

struct RegistrationRequest {
    string transactionId;
    int transactionBlockId;
    string registerAtUrl;
}

struct TwoPhaseCommitTransaction {
    string transactionId;
    string coordinationType = "2pc";
    coord:TransactionState state;
}

@http:ServiceConfig {basePath:"/"}
service<http:Service> TransactionSidecar bind sidecarEP {

    @http:ResourceConfig {
        methods:["POST"],
        body:"regReq"
    }
    register (endpoint conn, http:Request req, RegistrationRequest regReq) {
        http:Response res = {};

        string participantId = localParticipantId;
        string txnId = regReq.transactionId;
        int transactionBlockId = regReq.transactionBlockId;

        //TODO: set the proper protocol
        string protocol = "durable";
        //  "http://" + coordinatorHost + ":" + coordinatorPort + participant2pcCoordinatorBasePath + "/" + transactionBlockId;
        coord:Protocol[] protocols = [{name:protocol, url:"http://" + sidecarHost + ":" + sidecarPort + "/" + transactionBlockId}];
        var result = coord:registerParticipantWithRemoteInitiator(txnId, transactionBlockId,
                                                                  regReq.registerAtUrl, protocols);
        match result {
            coord:TransactionContext txnCtx => {
                io:println(txnCtx);
                res.statusCode = 200;
                res.setStringPayload("Registration with coordinator successful");
                TwoPhaseCommitTransaction txn = {transactionId:txnId, state:coord:TransactionState.ACTIVE};
                participatedTransactions[txnId] = txn;
            }
            error err => {
                res.statusCode = 500;
            }
        }
        var connResult = conn -> respond(res);
        match connResult {
            error err =>  log:printErrorCause("Sending response for register request failed", err);
            null => return;
        }
    }

    @http:ResourceConfig {
        methods:["POST"],
        path:"{transactionBlockId}/prepare",
        body:"prepareReq"
    }
    prepare (endpoint conn, http:Request req, int transactionBlockId, coord:PrepareRequest prepareReq) {
        http:Response res = {statusCode:500};
        string txnId = prepareReq.transactionId;
        log:printInfo("Prepare received for transaction: " + txnId);

        coord:PrepareResponse prepareRes = {};
        if(!participatedTransactions.hasKey(txnId)) {
            res.statusCode = 404;
            prepareRes.message = "Transaction-Unknown";
        } else {
            TwoPhaseCommitTransaction txn = participatedTransactions[txnId];
            // Send the prepare call to the main car and get the response
            string status = prepareMaincar(txn);
            prepareRes.message = status;
            var j =? <json>prepareRes;
            res.statusCode = 200;
            res.setJsonPayload(j);
        }
        var connResult = conn -> respond(res);
        match connResult {
            error err =>  log:printErrorCause("Sending response for prepare request failed", err);
            null => return;
        }
    }

    @http:ResourceConfig {
        methods:["POST"],
        path:"{transactionBlockId}/notify",
        body:"notifyReq"
    }
    notify (endpoint conn, http:Request req, int transactionBlockId, coord:NotifyRequest notifyReq) {
        http:Response res = {statusCode:500};
        string txnId = notifyReq.transactionId;
        log:printInfo("Notify(" + notifyReq.message + ") received for transaction: " + txnId);

        coord:NotifyResponse notifyRes = {};

        if (!participatedTransactions.hasKey(txnId)) {
            res.statusCode = 404;
            notifyRes.message = "Transaction-Unknown";
        } else {
            TwoPhaseCommitTransaction txn = participatedTransactions[txnId];

            if (notifyReq.message == coord:COMMAND_COMMIT) {
                if (txn.state != coord:TransactionState.PREPARED) {
                    res.statusCode = 400;
                    notifyRes.message = coord:OUTCOME_NOT_PREPARED;
                } else {
                    // send the notify(commit) to the maincar
                    var result = notifyMaincar(txnId, notifyReq.message);
                    match result {
                        string => {
                            res.statusCode = 200;
                            notifyRes.message = coord:OUTCOME_COMMITTED;
                        }
                        error => {
                            res.statusCode = 500;
                            log:printError("Committing maincar failed. Transaction:" + txnId);
                            notifyRes.message = coord:OUTCOME_FAILED_EOT;
                        }
                    }
                }
            } else if (notifyReq.message == coord:COMMAND_ABORT) {
                // send the notify(abort) to the maincar
                var result = notifyMaincar(txnId, notifyReq.message);
                match result {
                    string => {
                        res.statusCode = 200;
                        notifyRes.message = coord:OUTCOME_ABORTED;
                    }
                    error => {
                        res.statusCode = 500;
                        log:printError("Aborting maincar failed. Transaction:" + txnId);
                        notifyRes.message = coord:OUTCOME_FAILED_EOT;
                    }
                }
            }
            removeTransaction(txnId);
            var j =? <json>notifyRes;
            res.setJsonPayload(j);
            var connResult = conn -> respond(res);
            match connResult {
                error err =>  log:printErrorCause("Sending response for notify request for transaction " + txnId + " failed", err);
                null => return;
            }
        }
    }
}

function prepareMaincar(TwoPhaseCommitTransaction txn) returns string { // return status
    string status;
    string transactionId = txn.transactionId;
    var result = maincarEP -> prepare(transactionId);
    match result {
        error err => {
            log:printErrorCause("Maincar failed", err);
            removeTransaction(transactionId);
            status = coord:OUTCOME_ABORTED;
        }
        string str => {
            if (str == coord:OUTCOME_ABORTED) {
                log:printInfo("Maincar aborted.");
                removeTransaction(transactionId);
            } else if (str == coord:OUTCOME_COMMITTED) {
                log:printInfo("Maincar committed");
                removeTransaction(transactionId);
            } else if (str == coord:OUTCOME_READ_ONLY) {
                log:printInfo("Maincar read-only");
                removeTransaction(transactionId);
            } else if (str == coord:OUTCOME_PREPARED) {
                txn.state = coord:TransactionState.PREPARED;
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
    var result = maincarEP -> notify(transactionId, message);
    match result {
        error err => {
            log:printErrorCause("Maincar replied with an error", err);
            return err;
        }
        string notificationStatus => {
            if (notificationStatus == coord:OUTCOME_ABORTED) {
                log:printInfo("Maincar aborted");
            } else if (notificationStatus == coord:OUTCOME_COMMITTED) {
                log:printInfo("Maincar committed");
            }
            return notificationStatus;
        }
    }
}
