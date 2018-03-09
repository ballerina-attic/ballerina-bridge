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

const string TX_CALLBACK_PATH = "/ballerina_sc/transaction/callback";

// Exposed via a K8s service
// Add K82 annotation
@http:configuration {basePath:"/", port:9090}
service<http> sc_proxy {

    @http:resourceConfig {
        path:"/*"
    }
    resource ingressTraffic (http:Connection conn, http:InRequest req) {
        // Ingress traffic always talks to localhost
        endpoint<http:HttpClient> locationEP {
            create http:HttpClient("http://localhost:8080", {});
        }
        // Traffic coming into the pod
        // Sidecar features such as Transactions, OAuth token validation, enabling observability for services etc. are handled here.

        // Port needs to be resolved from the environment.

        log:printInfo("Ballerina Sidecar Ingress : " + req.rawPath);

        if (req.rawPath.equalsIgnoreCase(TX_CALLBACK_PATH) ) {
            handleTxCallback(conn, req);
        }

        transaction {
            http:InResponse clientResponse = {};
            http:HttpConnectorError err;
            http:OutResponse res = {};

            log:printInfo("Invoking service : " + req.rawPath);

            clientResponse, err = locationEP.forward(req.rawPath, req);
            if (err != null) {
                res.statusCode = 500;
                res.setStringPayload(err.message);

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

function handleTxCallback (http:Connection conn, http:InRequest req) {
    log:printInfo("TX callback ...");
    // ToDO :

}