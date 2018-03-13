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

package sidecar.springboot_helloworld;

import ballerina.net.http;
import ballerina.log;
import ballerinax.kubernetes;

@kubernetes:svc{}
@kubernetes:ingress{}
@http:configuration {
    basePath:"/", port:9090
}
service<http> sidecar {

    @http:resourceConfig {
        path:"/*"
    }
    resource ingressTraffic (http:Connection conn, http:InRequest req) {
        // Ingress traffic always talks to localhost
        endpoint<http:HttpClient> serviceEP {
            create http:HttpClient("http://localhost:8080", {});
        }

        // Traffic coming into the sidecar
        log:printTrace("Ballerina Sidecar Ingress : " + req.rawPath);

        http:InResponse clientResponse = {};
        http:HttpConnectorError err;

        log:printTrace("Invoking service : " + req.rawPath);
        clientResponse, err = serviceEP.forward(req.rawPath, req);

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
