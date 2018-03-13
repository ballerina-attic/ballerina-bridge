


1. Building Docker image for Spring Boot service 

`` mvn clean install dockerfile:build ``

2. Make sure you have build the required Ballerina Sidecar docker images. 

3. Update the K8s deployment descriptor with the respective docker image details the ports. 

4. Deploy 

`` kubectl create -f b6a_sc_spring_boot_hello_service.yml ``

5. Test the service. 

Get the NodePort for the service by using: 
`` kubectl describe service b6a-sc-springboot-hello

   Name:                     b6a-sc-springboot-hello
   Namespace:                default
   Labels:                   app=b6a-sc-springboot-hello
   Annotations:              <none>
   Selector:                 app=b6a-sc-springboot-hello
   Type:                     NodePort
   IP:                       10.107.210.108
   Port:                     <unset>  9090/TCP
   TargetPort:               9090/TCP
   NodePort:                 <unset>  31650/TCP
   Endpoints:                172.17.0.22:9090
   Session Affinity:         None
   External Traffic Policy:  Cluster ``


Invoke the service via: 

`` curl <k8S_host>:<node-port>/hello``

