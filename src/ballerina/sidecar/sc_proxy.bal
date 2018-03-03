package ballerina.sidecar;

import ballerina.net.http;
import ballerina.log;

// Exposed via a K8s service
// Add K82 annotations
@http:configuration {basePath:"/", port:9090}
service<http> sc_proxy {
    @http:resourceConfig {
        path:"/*"
    }
    resource ingressTraffic (http:Connection conn, http:InRequest req) {
        // Traffic coming into the pod
        // Sidecar features such as Transactions, OAuth token validation, enabling observability for services etc. are handled here.

        // Ingress endpoint always talks to localhost
        // Port needs to be resolved from the environment.
        endpoint<http:HttpClient> locationEP {
            create http:HttpClient("http://localhost:8080", {});
        }

        http:InResponse clientResponse = {};
        http:HttpConnectorError err;

        log:printInfo("Ballerina Sidecar Ingress");
        var requestURL = req.getProperty("REQUEST_URL");

        log:printInfo("Req : " + requestURL);
        clientResponse, err = locationEP.forward(requestURL, req);

        http:OutResponse res = {};
        if (err != null) {
            res.statusCode = 500;
            res.setStringPayload(err.message);
            _ = conn.respond(res);
        } else {
            _ = conn.forward(clientResponse);
        }
    }
}