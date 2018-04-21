import ballerina/io;
import ballerina/log;
import ballerina/http;

endpoint http:Listener participantAirlineService {
    port:7070
};


@http:ServiceConfig {
    basePath:"/airline"
}
service<http:Service> AirlineService  bind participantAirlineService {

    @http:ResourceConfig {
            path:"/reservation"
    }
    bookAirline(endpoint caller, http:Request req) {
        http:Response res = new;
        transaction with oncommit=onCommit, onabort=onAbort {
            json reqJ = check req.getJsonPayload();
            if(reqJ.airline.toString() == "delta") {
                io:println("Airline reservation done. -> Name - "
                        + reqJ.full_name.toString() + ", Airline - " + reqJ.airline.toString());
                res.setStringPayload("Airline reserved!  " + reqJ.full_name.toString() );
                _ = caller -> respond(res);
            } else {
                res.setStringPayload("Reservation Failed!");
                res.statusCode = http:INTERNAL_SERVER_ERROR_500;
                _ = caller -> respond(res);
                abort;
            }
        }
    }
}


function onAbort(string transactionid) {
    log:printInfo("--- onAbort ---");
}

function onCommit(string transactionid) {
    log:printInfo("--- onCommit ---");
}
