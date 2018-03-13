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

package ballerina.sidecar.security.jwt;

import ballerina.net.http;
import ballerina.log;
import ballerina.auth.jwtAuth;


// Exposed via a K8s service
// Add K82 annotation
@http:configuration {
    basePath:"/",
    httpsPort:9095,
    keyStoreFile:"${ballerina.home}/bre/security/ballerinaKeystore.p12",
    keyStorePassword:"ballerina",
    certPassword:"ballerina"
}
service<http> sidecar_jwt {

    @http:resourceConfig {
        path:"/*"
    }
    resource ingressTraffic (http:Connection conn, http:InRequest req) {
        // Ingress traffic always talks to localhost
        // Port needs to be resolved from the environment.
        endpoint<http:HttpClient> locationEP {
            create http:HttpClient("http://localhost:8080", {});
        }

        log:printInfo("Ballerina Sidecar Ingress : " + req.rawPath);


        jwtAuth:HttpJwtAuthnHandler handler = {};
        boolean isAuthenticated = false;
        if (handler.canHandle(req)) {
            isAuthenticated = handler.handle(req);
        }


        http:InResponse clientResponse = {};
        http:HttpConnectorError err;
        http:OutResponse res = {};

        log:printTrace("Invoking service : " + req.rawPath);
        log:printInfo("Invoking service : " + req.rawPath);

        clientResponse, err = locationEP.forward(req.rawPath, req);
        if (err != null || !isAuthenticated) {
            res.statusCode = 500;
            res.setStringPayload(err.message);
            _ = conn.respond(res);

        } else {
            _ = conn.forward(clientResponse);
        }
    }
}
