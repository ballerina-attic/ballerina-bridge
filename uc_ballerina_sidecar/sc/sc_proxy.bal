package sc;
import ballerina.net.http;
import ballerina.net.http.resiliency;

// WIP 
@http:configuration {basePath:"/"}
service<http> sc_proxy {

    @http:resourceConfig {
        path:"/"
    }
    resource egressTraffic (http:Connection conn, http:InRequest req) {
        // Traffic going out from the pod
        // Egress endpoints are resolved via K8s service discovery

        // Service calling external endpoint via Ballerina SC
        endpoint<resiliency:CircuitBreaker> redis {
            create resiliency:CircuitBreaker(create http:HttpClient("http://redis:8080", {endpointTimeout:2000}), 0.3, 20000);
        }

        http:InResponse clientResponse = {};
        http:HttpConnectorError err;

        clientResponse, err = redis.forward("/", req);

        if (err != null) {
            if (clientResponse == null) {
                http:OutResponse res = {};
                res.statusCode = 500;
                res.setStringPayload("server error");
                _ = conn.respond(res);
            }
        } else {
            _ = conn.forward(clientResponse);
        }
    }

    // Exposed via K8s service
    @http:resourceConfig {
        path:"/order"
    }
    resource ingressTraffic (http:Connection conn, http:InRequest req) {
        // Traffic coming into the pod
        // Can be used to implement scenarios such as distributed transactions


        // Ingress endpoint always talks to localhost
        endpoint<http:HttpClient> locationEP {
            create http:HttpClient("http://localhost:5000", {});
        }

        http:InResponse clientResponse = {};
        http:HttpConnectorError err;

        clientResponse, err = locationEP.forward("/", req);


        http:OutResponse res = {};
        if (err != null) {
            res.statusCode = 500;
            res.setStringPayload("server error");
            _ = conn.respond(res);
        } else {
            _ = conn.forward(clientResponse);
        }

    }



}