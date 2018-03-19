// Copyright (c) 2017 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package airline_svc_b6a;
import ballerina.log;
import ballerina.io;
import ballerina.net.http;

// Participant in the distributed transaction.

@http:configuration {
    basePath:"/flight",
    host:"localhost",
    port:8889
}
service<http> airline_service {
    string msg;

    @http:resourceConfig {
        path:"/reservation"
    }
    resource reserveFlight (http:Connection conn, http:InRequest req) {
        log:printInfo("Received flight reservation request");
        http:OutResponse res;

        // At the beginning of the transaction statement, since a transaction context has been received, this service
        // will register with the initiator as a participant.
        transaction {
            json reservationReq = req.getJsonPayload();
            msg = io:sprintf("Flight reservation request received. name:%j, airline:%j",
                             [reservationReq.full_name, reservationReq.airline]);

            log:printInfo(msg);
            if (reservationReq.airline.toString() == null) {
                abort;
                //res = {statusCode:500};
                //res.setJsonPayload(errRes);
            } else {
                json jsonRes = {"Airline reservation status ":reservationReq.airline, "name":reservationReq.full_name};
                res = {statusCode:200};
                res.setJsonPayload(jsonRes);
            }
            var err = conn.respond(res);
            if (err != null) {
                log:printErrorCause("Could not send response back to initiator", err);
            } else {
                log:printInfo("Sent response back to initiator");
            }
        } failed {
            log:printInfo("Transaction failed...");
        }
    }

    @http:resourceConfig {
        path:"/reservation",
        methods:["GET"]
    }
    resource getReservation (http:Connection conn, http:InRequest req) {
        log:printInfo("Received flight reservation request");
        http:OutResponse res;

        json jsonRes = {"message":msg};
        res = {statusCode:200};
        res.setJsonPayload(jsonRes);

        var err = conn.respond(res);
        if (err != null) {
            log:printErrorCause("Could not send response back", err);
        } else {
            log:printInfo("Sent response back");
        }
    }
}