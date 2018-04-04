import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/config;
import ballerinax/kubernetes;
import ballerina/os;

// Constants for Env variables
const string BRIDGE_HTTP_PORT_STR = "SIDECAR_HTTP_PORT";
const string SERVICE_PORT_STR = "SERVICE_PORT";

const int bridge_service_port = 9090;
const int primary_service_port = 8080;

// Service endpoint of the bridge service

@kubernetes :Ingress{
    hostname:"ballerina.bridge.io",
    name:"ballerina-bridge-ingress",
    path:"/"
}

@kubernetes:Service {
    serviceType:"NodePort",
    name:"ballerina-bridge-service"
}
endpoint http:ServiceEndpoint bridgeIngressServiceEP {
    port:9090
};

// Client endpoint that talks to primary service
endpoint http:SimpleClientEndpoint primaryServiceClientEP {
    url: "http://localhost:" + primary_service_port
};

@kubernetes:Deployment {
    image: "kasunindrasiri/ballerina-bridge",
    name: "ballerina-bridge"
}


@http:ServiceConfig {
    basePath:"/"
}
service<http:Service> bridge bind bridgeIngressServiceEP {
    @http:ResourceConfig {
        path:"/*"
    }
    ingressTraffic (endpoint sourceEndpoint, http:Request request) {
        log:printInfo("Ballerina bridge Ingress : " + request.rawPath);
        var res = primaryServiceClientEP -> forward(request.rawPath, request);
        match res {
            http:Response response => {
                _ = sourceEndpoint -> forward(response);
            }
            http:HttpConnectorError err => {
                http:Response response = {};
                response.statusCode = 500;
                response.setStringPayload(err.message);
                _ = sourceEndpoint -> respond(response);
            }
        }
    }
}