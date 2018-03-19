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

const int scHttpPort = initPort(SIDECAR_HTTP_PORT);
const int serviceHttpPort = initPort(SERVICE_PORT);


@kubernetes:svc {
    name:"ballerina-sidecar-svc"
}
@kubernetes:deployment {
    image:"kasunindrasiri/ballerina-sidecar:1.0.0",
    env:"SIDECAR_HTTP_PORT:9090, SERVICE_PORT:8080",
    name: "ballerina-sidecar"
}
@kubernetes :ingress {
    hostname:"ballerina.sidecar.io",
    name:"ballerina-sidecar-ingress",
    path:"/"
}
@http:configuration {basePath:"/", port:scHttpPort}
service<http> sidecar {

    @http:resourceConfig {
        path:"/*"
    }
    resource ingressTraffic (http:Connection conn, http:InRequest req) {
        // Ingress traffic always talks to localhost
        endpoint<http:HttpClient> locationEP {
            create http:HttpClient("http://localhost:" + serviceHttpPort, {});
        }
        // Sidecar features such as Transactions, Security (JWT, Basic-Auth tokens, and Authorization) validation, Enabling observability,
        // are applied inside the Sidecar's routing logic.

        log:printTrace("Ballerina Sidecar Ingress : " + req.rawPath);

        transaction {
            http:InResponse clientResponse = {};
            http:HttpConnectorError err;
            http:OutResponse res = {};

            clientResponse, err = locationEP.forward(req.rawPath, req);
            if (err != null) {
                res.statusCode = 500;
                res.setStringPayload(err.message);
                _ = conn.respond(res);
            } else {
                var statusCode, _ = (int)clientResponse.statusCode;
                _ = conn.forward(clientResponse);
                if (statusCode == 500) {
                    abort;
                }
            }
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
