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

import ballerina.net.http;
import ballerina.transactions.coordinator as coord;
import ballerina.util;
import ballerina.io;
import ballerina.log;

const string sidecarHost = "10.100.1.182"; //TODO: get this from an env var/config API
const int sidecarPort = 33333; //TODO: get this from an env var/config API
const string maincarUrl = "http://10.100.5.131:8080/transaction"; //TODO: get this from an env var/config API

endpoint http:ServiceEndpoint sidecarEP {
    host: sidecarHost,
    port: sidecarPort
};

endpoint coord:Participant2pcClientEP maincarEP {
    participantURL: maincarUrl,
    endpointTimeout:120000, 
    retryConfig:{count:5, interval:5000}
};

string mainCarUrl;
map participatedTransactions = {};
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
        methods:["POST"]
    }
    register (endpoint conn, http:Request req) {
        var payload, payloadError = req.getJsonPayload();
        http:Response res;
        if (payloadError != null) {
            res = {statusCode:400};
            coord:RequestError err = {errorMessage:"Bad Request"};
            var resPayload, _ = <json>err;
            res.setJsonPayload(resPayload);
            var connErr = conn -> respond(res);
            if (connErr != null) {
                log:printErrorCause("Sending response to Bad Request for register request failed", (error)connErr);
            }
        } else {
            var regReq, _ = <RegistrationRequest>(payload);
            string participantId = localParticipantId ;
            string txnId = regReq.transactionId;
            int transactionBlockId = regReq.transactionBlockId;

            //TODO: set the proper protocol
            string protocol = "durable";
            //  "http://" + coordinatorHost + ":" + coordinatorPort + participant2pcCoordinatorBasePath + "/" + transactionBlockId;
            coord:Protocol[] protocols = [{name:protocol, url:"http://" + sidecarHost + ":" + sidecarPort + "/" + transactionBlockId}];
            var txnCtx, err = coord:registerParticipantWithRemoteInitiator(txnId, 
                                                                            transactionBlockId, 
                                                                            regReq.registerAtUrl,
                                                                            protocols);
            io:println(txnCtx);
            io:println(err);
            if(err != null) {
                res = {statusCode:500};
            } else {
                res = {statusCode:200};
                res.setStringPayload("Registration with coordinator successful");
                TwoPhaseCommitTransaction txn = {transactionId: txnId, state: coord:TransactionState.ACTIVE};
                participatedTransactions[txnId] = txn;
            }
            var connErr = conn -> respond(res);
            if (connErr != null) {
                log:printErrorCause("Sending response for register request failed", (error)connErr);
            }
        }
    }

    @http:ResourceConfig {
        methods:["POST"],
        path:"{transactionBlockId}/prepare"
    }
    prepare (endpoint conn, http:Request req, string transactionBlockId) {
        http:Response res = {statusCode:500};
        var payload, payloadError = req.getJsonPayload();
        var txnBlockId, txnBlockIdConversionErr = <int>transactionBlockId;

        if (payloadError != null || txnBlockIdConversionErr != null) {
            res = {statusCode:400};
            coord:RequestError err = {errorMessage:"Bad Request"};
            var resPayload, _ = <json>err;
            res.setJsonPayload(resPayload);
            var connErr = conn -> respond(res);
            if (connErr != null) {
                log:printErrorCause("Sending response to Bad Request for prepare request failed", (error)connErr);
            }
        } else {
            var prepareReq, _ = <coord:PrepareRequest>payload;
            string txnId = prepareReq.transactionId;
            log:printInfo("Prepare received for transaction: " + txnId);
            coord:PrepareResponse prepareRes;
            var txn, _ = (TwoPhaseCommitTransaction)participatedTransactions[txnId];
            if (txn == null) {
                res = {statusCode:404};
                prepareRes = {message:"Transaction-Unknown"};
            } else {
                // Send the prepare call to the main car and get the response
                string status = prepareMaincar(txn);
                prepareRes = {message: status};
                var j, _ = <json>prepareRes;
                res = {statusCode:200};
                res.setJsonPayload(j);
            }
        }
        var connErr = conn -> respond(res);
        if (connErr != null) {
            log:printErrorCause("Sending response for prepare request failed", (error)connErr);
        }
    }

    @http:ResourceConfig {
        methods:["POST"],
        path:"{transactionBlockId}/notify"
    }
    notify (endpoint conn, http:Request req, string transactionBlockId) {
        http:Response res;
        var payload, payloadError = req.getJsonPayload();
        var txnBlockId, txnBlockIdConversionErr = <int>transactionBlockId;
        if (payloadError != null || txnBlockIdConversionErr != null) {
            res = {statusCode:400};
            coord:RequestError err = {errorMessage:"Bad Request"};
            var resPayload, _ = <json>err;
            res.setJsonPayload(resPayload);
            var connErr = conn -> respond(res);
            if (connErr != null) {
                log:printErrorCause("Sending response to Bad Request for notify request failed", (error)connErr);
            }
        } else {
            var notifyReq, _ = <coord:NotifyRequest>payload;
            string txnId = notifyReq.transactionId;
            log:printInfo("Notify(" + notifyReq.message + ") received for transaction: " + txnId);

            coord:NotifyResponse notifyRes;
            var txn, _ = (TwoPhaseCommitTransaction)participatedTransactions[txnId];
            if (txn == null) {
                res = {statusCode:404};
                notifyRes = {message:"Transaction-Unknown"};
            } else {
                if (notifyReq.message == "commit") {
                    if (txn.state != coord:TransactionState.PREPARED) {
                        res = {statusCode:400};
                        notifyRes = {message:"Not-Prepared"};
                    } else {
                        // send the notify(commit) to the maincar
                        var status, err = notifyMaincar(txnId, notifyReq.message);
                        if(err == null) {
                            res = {statusCode:200};    
                            notifyRes = {message:"Committed"};
                        } else {
                            res = {statusCode:500};
                            log:printError("Committing maincar failed. Transaction:" + txnId);
                            notifyRes = {message:"Failed-EOT"};
                        }
                    }
                } else if (notifyReq.message == "abort") {
                    // send the notify(abort) to the maincar
                    var status, err = notifyMaincar(txnId, notifyReq.message);
                    if(err == null) {
                        res = {statusCode:200};    
                        notifyRes = {message:"Aborted"};
                    } else {
                        res = {statusCode:500};
                        log:printError("Aborting maincar failed. Transaction:" + txnId);
                        notifyRes = {message:"Failed-EOT"};
                    }
                }
                removeTransaction(txnId);
            }
            var j, _ = <json>notifyRes;
            res.setJsonPayload(j);
            var connErr = conn -> respond(res);
            if (connErr != null) {
                log:printErrorCause("Sending response for notify request for transaction " + txnId +
                                    " failed", (error)connErr);
            }
        }
    }
}

function prepareMaincar(TwoPhaseCommitTransaction txn) returns (string status){
    error err;
    string transactionId = txn.transactionId;
    status, err = maincarEP -> prepare(transactionId);
    if (status == "aborted") {
        log:printInfo("Maincar aborted.");
        removeTransaction(transactionId);
    } else if (status == "committed") {
        log:printInfo("Maincar committed");
        removeTransaction(transactionId);
    } else if (status == "read-only") {
        log:printInfo("Maincar read-only");
        removeTransaction(transactionId);
    } else if (err != null) {
        log:printErrorCause("Maincar failed", err);
        removeTransaction(transactionId);
        status = "aborted";
    } else if (status == "prepared") {
        txn.state = coord:TransactionState.PREPARED;
        log:printInfo("Maincar prepared");
    } else {
        string msg = "Invalid maincar status: " + status;
        log:printInfo(msg);
        error e = {message: msg};
        throw e;
    }
    return;
}

function removeTransaction(string transactionId) {
    if(!participatedTransactions.remove(transactionId)) {
        log:printWarn("Removing transaction: " + transactionId + " failed");
    }
}

function notifyMaincar (string transactionId, string message) returns (string status, error err) {
    log:printInfo("Notify(" + message + ") maincar");
    var notificationStatus, participantErr, communicationErr = maincarEP -> notify(transactionId, message);
    status = notificationStatus;
    if (communicationErr != null) {
        if (message != "abort") {
            err = communicationErr;
        }
        log:printErrorCause("Communication error occurred while notify(" + message + ") maincar. 
                            Transaction: " + transactionId, communicationErr);
    } else if (participantErr != null) { // participant may return "Transaction-Unknown", "Not-Prepared" or "Failed-EOT"
        log:printErrorCause("Maincar replied with an error", participantErr);
        err = participantErr;
    } else if (notificationStatus == "aborted") {
        log:printInfo("Maincar aborted");
    } else if (notificationStatus == "committed") {
        log:printInfo("Maincar committed");
    }
    return;
}
