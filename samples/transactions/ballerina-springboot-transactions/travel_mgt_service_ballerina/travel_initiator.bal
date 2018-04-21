

import ballerina/http;
import ballerina/io;

endpoint http:Listener initiatorEP {
    port:6060
};


endpoint http:Client participantAirlineService {
    url: "http://localhost:7070"
};

endpoint http:Client participantHotelService {
    url: "http://localhost:9090"
};


@http:ServiceConfig {
    basePath:"/"
}
service<http:Service> InitiatorService bind initiatorEP {


    @http:ResourceConfig {
        path:"/travel"
    }
    bookTrip (endpoint caller, http:Request req) {

        http:Response airlineRes = new;
        http:Response hotelRes = new;
        http:Request hotelReq = new;

        json reqJ = check req.getJsonPayload();
        string name = reqJ.full_name.toString();
        string checkIn = reqJ.start_date.toString();
        string checkOut = reqJ.end_date.toString();
        json hotelReqJ = { fullName: name, checkIn: checkIn, checkOut: checkOut, rooms: 1 };
        hotelReq.setJsonPayload(hotelReqJ);

        transaction {
            airlineRes = check participantAirlineService -> post("/airline/reservation", req);
            hotelRes = check participantHotelService -> post("/reservation/hotel", hotelReq);
            io:println("Service calls are completed");
        }
        _ = caller -> respond(hotelRes);
    }
}


//function onAbort(string transactionid) {
//    state.abortedFunctionCalled = true;
//}
//
//function onCommit(string transactionid) {
//    state.committedFunctionCalled = true;
//}
//
//function onLocalParticipantAbort(string transactionid) {
//    state.localParticipantAbortedFunctionCalled = true;
//}
//
//function onLocalParticipantCommit(string transactionid) {
//    state.localParticipantCommittedFunctionCalled = true;
//}


