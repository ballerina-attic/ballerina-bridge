// Copyright (c) 2017 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

package ballerina.sidecar;

import ballerina.net.http;
import ballerina.log;
import ballerina.config;
import ballerinax.kubernetes;
import ballerina.os;


const string SIDECAR_HTTP_PORT = "SIDECAR_HTTP_PORT";
const string SERVICE_PORT = "SERVICE_PORT";

//const int scHttpPort = initPort(SIDECAR_HTTP_PORT);
const int serviceHttpPort = initPort(SERVICE_PORT);

@kubernetes:svc {
    name:"ballerina-sidecar-svc"
}

// Using port from an integer variable is not working in
endpoint http:ServiceEndpoint sidecarIngressServiceEP {
    port:9090
};

endpoint http:ClientEndpoint primaryServiceClientEP {
  targets: [
    { uri: "http://localhost:" + 8080}
  ]
};

@kubernetes:deployment {
    image: "kasunindrasiri/ballerina-sidecar",
    env:"SIDECAR_HTTP_PORT:9090, SERVICE_PORT:8080",
    name: "ballerina-sidecar"
}
@kubernetes :ingress {
    hostname:"ballerina.sidecar.io",
    name:"ballerina-sidecar-ingress",
    path:"/"
}


@http:serviceConfig {
    basePath:"/"
}
service<http:Service> sidecar bind sidecarIngressServiceEP {

    @http:resourceConfig {
        path:"/*"
    }
    ingressTraffic (endpoint client, http:Request request) {
        // Sidecar features such as Transactions, Security (JWT, Basic-Auth tokens, and Authorization) validation, Enabling observability,
        // are applied inside the Sidecar's routing logic.

        log:printTrace("Ballerina Sidecar Ingress : " + request.rawPath);
        http:HttpConnectorError err;
        http:Response clientResponse = {};

        clientResponse, err = primaryServiceClientEP -> forward(request.rawPath, request);

        http:Response res = {};
        if (err != null) {
           res.statusCode = 500;
           res.setStringPayload(err.message);
           _ = client -> respond(res);
       } else {
           _ = client -> forward(clientResponse);
       }
    }
}

function initPort (string envVarName) (int) {
    string portStr = os:getEnv(envVarName);
    var port, typeConversionErr = <int> portStr;
    if (typeConversionErr != null) {
        log:printError("Invalid port : " + portStr + " : " + typeConversionErr.message);
    }
    return port;
}
