package ballerina.sidecar;

import ballerina.net.http;
import ballerina.log;

const string TX_CALLBACK_PATH = "/ballerina_sc/transaction/callback";

// Exposed via a K8s service
// Add K82 annotation
@http:configuration {basePath:"/", port:9090}
service<http> sc_proxy {

    @http:resourceConfig {
        path:"/*"
    }
    resource ingressTraffic (http:Connection conn, http:InRequest req) {
        // Traffic coming into the pod
        // Sidecar features such as Transactions, OAuth token validation, enabling observability for services etc. are handled here.

        // Port needs to be resolved from the environment.

        log:printInfo("Ballerina Sidecar Ingress : " + req.rawPath);
        if (req.rawPath.equalsIgnoreCase(TX_CALLBACK_PATH) ) {
            handleTxCallback(conn, req);
        }

        // ToDO : FIX : Identify whether the request is part of a distributed TX.
        boolean  isTransactional = true;

        if (isTransactional) {
            transaction {
                callPrimaryService(conn, req);
            }
        } else {
            callPrimaryService(conn, req);
        }
    }

}

function callPrimaryService(http:Connection conn, http:InRequest req) {

    // Ingress traffic always talks to localhost
    endpoint<http:HttpClient> locationEP {
        create http:HttpClient("http://localhost:8080", {});
    }

    http:InResponse clientResponse = {};
    http:HttpConnectorError err;
    http:OutResponse res = {};

    log:printInfo("Invoking service : " + req.rawPath);

    clientResponse, err = locationEP.forward(req.rawPath, req);
    if (err != null) {
        res.statusCode = 500;
        res.setStringPayload(err.message);
        _ = conn.respond(res);
    } else {
        _ = conn.forward(clientResponse);
    }

}

function handleTxCallback (http:Connection conn, http:InRequest req) {
    log:printInfo("TX callback ...");
    // ToDO :

}