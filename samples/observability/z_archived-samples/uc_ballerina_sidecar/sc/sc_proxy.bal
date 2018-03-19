package sc;
import ballerina.net.http;
import ballerina.net.http.resiliency;

// Mock implementation of a Ballerina Sidecar

@http:configuration {basePath:"/*"}
service<http> sc_proxy {
    // Exposed via K8s service
    resource ingressTraffic (http:Connection conn, http:InRequest req) {
        // Traffic coming into the pod
        // Sidecar features such as Transactions, OAuth token validation, enabling observability for services etc. are handled here.

        // Ingress endpoint always talks to localhost
        // Port needs to be resolved from the environment.
        endpoint<http:HttpClient> locationEP {
            create http:HttpClient("http://localhost:5000", {});
        }

        http:InResponse clientResponse = {};
        http:HttpConnectorError err;

        clientResponse, err = locationEP.forward("/", req);

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