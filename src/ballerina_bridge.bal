import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/config;
import ballerinax/kubernetes;
import ballerina/os;

// Constants for Env variables
@final string BRIDGE_HTTP_PORT_STR = "SIDECAR_HTTP_PORT";
@final string SERVICE_PORT_STR = "SERVICE_PORT";

@final int bridge_service_port = 9090;
@final int primary_service_port = 8080;

// Service endpoint of the bridge service

@kubernetes :Ingress {
    hostname:"ballerina.bridge.io",
    name:"ballerina-bridge-ingress",
    path:"/"
}

@kubernetes:Service {
    serviceType:"NodePort",
    name:"ballerina-bridge-service"
}
endpoint http:Listener bridgeIngressServiceEP {
    port:9090
};

// Client endpoint that talks to primary service
endpoint http:SimpleClient primaryServiceClientEP {
    url: "http://localhost:" + primary_service_port
};

@kubernetes:Deployment {
    image: "kasunindrasiri/ballerina-bridge",
    name: "ballerina-bridge"
}

//@kubernetes:ConfigMap{
//    configMaps:[
//               {name:"ballerina-config", mountPath:"/home/ballerina", isBallerinaConf:true,
//                   data:["./bridge-config/ballerina.conf"]
//               }
//               ]
//}

@kubernetes:ConfigMap{
    configMaps:[
               {name:"ballerina-config", mountPath:"/home/ballerina", isBallerinaConf:true,
                   data:["./bridge-config/ballerina.conf"]
               }
               ]
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
        var res = primaryServiceClientEP -> forward(untaint request.rawPath, request);
        match res {
            http:Response response => {
                _ = sourceEndpoint -> respond(response);
            }
            http:HttpConnectorError err => {
                http:Response response = new;
                response.statusCode = 500;
                response.setStringPayload(err.message);
                _ = sourceEndpoint -> respond(response);
            }
        }
    }
}