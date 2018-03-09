package ballerina-airline-svc; 
import ballerina.log;
import ballerina.io;
import ballerina.net.http;

// This service is a participant in the distributed transaction. It will get infected when it receives a transaction
// context from the participant. The transaction context, in the HTTP case, will be passed in as custom HTTP headers.
@http:configuration {
    basePath:"/flight",
    host:"localhost",
    port:8889
}
service<http> FlightService {
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
            json updateReq = req.getJsonPayload();
            msg = io:sprintf("Flight reservation request received. flight:%j, count:%j",
                             [updateReq.flight, updateReq.count]);
            var count,err = (int)updateReq.count;
            log:printInfo(msg);
            if (count > 5) {
                abort;
                //res = {statusCode:500};
                //json errRes = {"message":"Reservation count cannot exeed 5"};
                //res.setJsonPayload(errRes);
            } else {
                json jsonRes = {"message":"making reservation"};
                res = {statusCode:200};
                res.setJsonPayload(jsonRes);
            }
            err = conn.respond(res);
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