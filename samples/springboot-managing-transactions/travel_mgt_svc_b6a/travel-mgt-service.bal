
package travel_mgt_svc_b6a; 
import ballerina.math;
import ballerina.net.http;
import ballerina.log;
import ballerina.io;

// This is the initiator of the distributed transaction
@http:configuration {
    basePath:"/",
    host:"localhost",
    port:8000
}
service<http> BookingService {

    @http:resourceConfig {
        methods:["GET"],
        path:"/"
    }
    resource init (http:Connection conn, http:InRequest req) {
        http:OutResponse res;
        log:printInfo("Initiating booking transaction...");

        // When the transaction statement starts, a distributed transaction context will be created.
        transaction {
            // When a participant is called, the transaction context will be propagated and that participant
            // will get infected, and join the distributed transaction.
            boolean flightRes = callFlightService();
            boolean hotelRes = callHotelService();
            if (flightRes && hotelRes) {
                res = {statusCode:200};
            } else {
                res = {statusCode:500};
            }

        }
        // As soon as the transaction block ends, the 2-phase commit coordination protocol will run. All participants
        // will be prepared and then depending on the join outcome, either a notify commit or notify abort will
        // be sent to the participants.

        var err = conn.respond(res);
        if (err != null) {
            log:printErrorCause("Could not send response back to client", err);
        } else {
            log:printInfo("Sent response back to client");
        }
    }
}

function callFlightService () returns (boolean successful) {
    endpoint<FlightClient> flightEP {
        create FlightClient();
    }

    int count = 3;
    json bizReq = {flight:"QR201", count:count};
    var _, e = flightEP.reserveFlight(bizReq, "127.0.0.1", 8889);
    if (e != null) {
        successful = false;
    } else {
        successful = true;
    }
    return;
}

function callHotelService () returns (boolean successful) {
    endpoint<HotelClient> hotelEP {
        create HotelClient();
    }

    json bizReq = {fullName:"Foo Bar", checkIn:"01/20/2018",
                      checkOut:"1/25/2018", rooms:2};
    var _, e = hotelEP.reserveHotel(bizReq, "127.0.0.1", 9090);
    if (e != null) {
        successful = false;
    } else {
        successful = true;
    }
    return;
}

public connector FlightClient() {

    action reserveFlight (json bizReq, string host, int port) returns (json jsonRes, error err) {
        endpoint<http:HttpClient> bizEP {
            create http:HttpClient("http://" + host + ":" + port + "/flight/reservation", {});
        }
        http:OutRequest req = {};
        req.setJsonPayload(bizReq);
        var res, e = bizEP.post("", req);
        log:printInfo("Got response from : Airline Service");
        if (e == null) {
            if (res.statusCode != 200) {
                err = {message:"Error occurred"};
            } else {
                jsonRes = res.getJsonPayload();
            }
        } else {
            err = (error)e;
        }
        return;
    }
}

public connector HotelClient () {

    action reserveHotel (json bizReq, string host, int port) returns (json jsonRes, error err) {
        endpoint<http:HttpClient> bizEP {
            create http:HttpClient("http://" + host + ":" + port + "/reservation/hotel", {});
        }
        http:OutRequest req = {};
        req.setJsonPayload(bizReq);
        var res, e = bizEP.post("", req);
        log:printInfo("Got response from : Hotel Service");
        if (e == null) {
            if (res.statusCode != 200) {
                err = {message:"Error occurred"};
            } else {
                jsonRes = res.getJsonPayload();
            }
        } else {
            err = (error)e;
        }
        return;
    }
}