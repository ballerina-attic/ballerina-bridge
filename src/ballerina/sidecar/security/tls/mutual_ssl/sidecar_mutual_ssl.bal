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

package ballerina.sidecar.security.tls.mutual_ssl;

import ballerina.net.http;
import ballerina.log;

// Exposed via a K8s service
// Add K82 annotation
@http:configuration {
    basePath:"/hello",
    httpsPort:9095,
    keyStoreFile:"${ballerina.home}/bre/security/ballerinaKeystore.p12",
    keyStorePassword:"ballerina",
    certPassword:"ballerina",
    sslVerifyClient:"require",
    trustStoreFile:"${ballerina.home}/bre/security/ballerinaTruststore.p12",
    trustStorePassword:"ballerina",
    ciphers:"TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA",
    sslEnabledProtocols:"TLSv1.2,TLSv1.1"
}
service<http> sidecar_mutual_ssl {

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

        http:InResponse clientResponse = {};
        http:HttpConnectorError err;
        http:OutResponse res = {};

        log:printTrace("Invoking service : " + req.rawPath);
        log:printInfo("Invoking service : " + req.rawPath);

        clientResponse, err = locationEP.forward(req.rawPath, req);
        if (err != null) {
            res.statusCode = 500;
            res.setStringPayload(err.message);

        } else {
            _ = conn.forward(clientResponse);
        }
    }
}
