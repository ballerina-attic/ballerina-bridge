package ballerina.sidecar;

import ballerina.net.http;

service<http> helloWorld {

    resource sayHello (http:Connection conn, http:InRequest req) {
        http:OutResponse res = {};
        res.setStringPayload("Hello, World!");
        _ = conn.respond(res);
    }
}
