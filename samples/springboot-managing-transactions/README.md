# Ballerina Sidecar 


1. Build Ballerina executable archive:

`` $ballerina build ballerina/sidecar   ``

2. Building Ballerina Sidecar Image 

`` $ballerina docker sc_proxy.balx -t kasunindrasiri/ballerinasidecar ``

3. Create the required docker images for the services that you want to run with the Sidecar and 
deploy it into Kubernetes (e.g. samples/springboot-helloworld)

