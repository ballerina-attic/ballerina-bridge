# Auto Generated Dockerfile

FROM ballerina/ballerina:0.970.0
LABEL maintainer="dev@ballerina.io"

COPY ballerina_bridge_sidecar.balx /home/ballerina 

EXPOSE  9090 9091

CMD ballerina run ballerina_bridge_sidecar.balx --config ${CONFIG_FILE} 
