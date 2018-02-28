package ballerinahelloworld;
import ballerina.net.http;


@http:configuration {basePath:"/"}
service<http> helloWorld {

    @http:resourceConfig {
        methods:["GET"],
        path:"/ballerina"
    }
    resource sayHello (http:Connection conn, http:InRequest req) {
        http:OutResponse res = {};

        res.setStringPayload("Hello, Ballerina World!");

        _ = conn.respond(res);
    }
}