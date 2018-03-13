# Running Spring Boot HelloWorld service with Ballerina Sidecar 


- The Spring Boot HelloWorld service is located at `` ballerina-sidecar/samples/getting-started/springboot-helloworld/service`` directory.  

- You can build the executable and the docker image for Spring Boot HelloWorld service using the following mvn command.  

`` $ mvn clean install -Ddocker.image.prefix=<your-docker-image-prefix> dockerfile:build ``

- Building Ballerina executable archive, docker image and K8s artifacts for the sidecar. 
To do this, you can run the following command from the `` ballerina-sidecar/samples/getting-started/springboot-helloworld `` directory. 

`` $ ballerina build sidecar/sbhelloworld``

This command creates the generates the Kubernetes artifacts at`` target/sbhelloworld/kubernetes ``. 

## Running on Kubernetes  

- Inject your Spring Boot HelloWorld service container into the deployment descriptor which is created from the previous step. You only need to change the `` sbhelloworld-deployment.yaml `` as follows:  

```
        ... 
        
       spec:
         containers:
         - name: springboot-helloworld
           image: my_repo/ballerina_sidecar_springboot_helloworld
           imagePullPolicy: Always 
           ports:
           - containerPort: 8080
         - args: [] 
         
         ... 
```
- Now you can deploy the Kubernetes artifacts with `` kubectl create -f target/sbhelloworld/kubernetes``. With successful execution, you should see:

```
    $ kubectl create -f target/sbhelloworld/kubernetes
        deployment "sbhelloworld-deployment" created
        ingress "sidecar" created
        service "sidecar" created
```

- Verify Kubernetes deployment,service and ingress is running. 

```

$kubectl get svc

NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP          4h
sidecar      NodePort    10.104.175.28   <none>        9090:31493/TCP   3h


kubectl get deploy
NAME                         DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
hello-world-k8s-deployment   1         1         1            1           4h
sbhelloworld-deployment      1         1         1            1           3h

kubectl get pods
NAME                                         READY     STATUS    RESTARTS   AGE
hello-world-k8s-deployment-bf8f98c7c-ql6wc   1/1       Running   0          4h
sbhelloworld-deployment-7d766dbf75-6dbxb     2/2       Running   0          3h

kubectl get ingress
NAME         HOSTS            ADDRESS   PORTS     AGE
helloworld   helloworld.com             80, 443   4h
sidecar      sidecar.com                80, 443   3h

```

- Access the sidecar service via Node port or Ingress. 

Node Port: 
```
curl http://localhost:31493/hello
 Hello World, from Spring Boot and Ballerina Sidecar!

```

Ingress: 

Add /etc/host entry to match hostname. 

```
127.0.0.1 helloworld.com

``` 
Access the service

```
$ curl http://helloworld.com/hello
 Hello World, from Spring Boot and Ballerina Sidecar!
```


