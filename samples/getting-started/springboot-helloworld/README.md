# Running Spring Boot HelloWorld service with Ballerina Sidecar 

## Use Case 

This sample demonstrate a how a simple Spring Boot service can be deployed with Ballerina Sidecar. 

![Ballerina Sidecar with SpringBoot](images/getting_started.png "Ballerina Sidecar with SpringBoot")


### Building the Spring Boot service 
- The Spring Boot HelloWorld service is located at `` ballerina-sidecar/samples/getting-started/springboot-helloworld/service`` directory.  

- You can build the executable and the docker image for the Spring Boot HelloWorld service using the following mvn command.  

    `` $ mvn clean install -Ddocker.image.prefix=<your-docker-image-prefix> dockerfile:build ``

## Running on Kubernetes  

- The Ballerina Sidecar ships with the Kubernetes deployment artifacts that you can use to deploy sidecar with your non-ballerina services. They are located in `` src/kubernetes``. 
- Copy ``src/kubernetes`` artifacts to `` samples/getting-started `` and inject your Spring Boot service deployment information to the deployment descriptor. 
- You can do this by changing the `` kubernetes/sidecar-deployment.yaml `` as follows:  

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
- Now you can deploy the Kubernetes artifacts with `` kubectl create -f ./samples/getting-started/kubernetes``. If the deployment is successful, you should see:

```
    $ kubectl create -f target/sbhelloworld/kubernetes
        deployment "ballerina-sidecar" created
        ingress "ballerina-sidecar-ingress" created
        service "ballerina-sidecar-svc" created
```

- Verify Kubernetes deployment, service and ingress is running. 

```

$ kubectl get svc

NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
ballerina-sidecar-svc   NodePort    10.108.155.112   <none>        9090:30824/TCP   59s


$ kubectl get deploy
NAME                         DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
ballerina-sidecar            1         1         1            1           1m

$ kubectl get pods
NAME                                         READY     STATUS    RESTARTS   AGE
ballerina-sidecar-5b9bb94b44-v97xs           1/1       Running   0          1m

$ kubectl get ingress
NAME                        HOSTS                  ADDRESS   PORTS     AGE
ballerina-sidecar-ingress   ballerina.sidecar.io             80, 443   1m

```

- Access the sidecar service via Node port or Ingress. 

Node Port: 
You can access the service via Node Port as follows. 
```
curl http://localhost:31493/hello
 Hello World, from Spring Boot and Ballerina Sidecar!

```

Ingress: 
To access the service via Ingress interface, you should modify the following entry. 
Add /etc/host entry to match hostname. 

```
127.0.0.1 helloworld.com

``` 
Access the service

```
$ curl http://helloworld.com/hello
 Hello World, from Spring Boot and Ballerina Sidecar!
```


## Running locally 
  

- Run the sidecar proxy 
``` 
ballerina run sbhelloworld.balx 
ballerina: deploying service(s) in 'sbhelloworld.balx'
ballerina: started HTTP/WS server connector 0.0.0.0:9090

```

- Run the Spring Boot Helloworld service 

``` 
$ java -jar target/springboot-helloworld-1.0-SNAPSHOT.jar

java -jar target/springboot-helloworld-1.0-SNAPSHOT.jar

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::        (v2.0.0.RELEASE)

2018-03-12 17:43:19.058  INFO 50560 --- [           main] ballerina_sidecar.SpringBootHelloWorld   : Starting SpringBootHelloWorld v1.0-SNAPSHOT on Kas-HS.local with PID 50560 (/Users/kasun/development/source/git/kasun04/ballerina-sidecar/samples/getting-started/springboot-helloworld/service/target/springboot-helloworld-1.0-SNAPSHOT.jar started by kasun in /Users/kasun/development/source/git/kasun04/ballerina-sidecar/samples/getting-started/springboot-helloworld/service)
2018-03-12 17:43:19.060  INFO 50560 --- [           main] ballerina_sidecar.SpringBootHelloWorld   : No active profile set, falling back to default profiles: default
2018-03-12 17:43:19.123  INFO 50560 --- [           main] ConfigServletWebServerApplicationContext : Refreshing org.springframework.boot.web.servlet.context.AnnotationConfigServletWebServerApplicationContext@161cd475: startup date [Mon Mar 12 17:43:19 PDT 2018]; root of context hierarchy
2018-03-12 17:43:20.217  INFO 50560 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat initialized with port(s): 8080 (http)
2018-03-12 17:43:20.251  INFO 50560 --- [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2018-03-12 17:43:20.251  INFO 50560 --- [           main] org.apache.catalina.core.StandardEngine  : Starting Servlet Engine: Apache Tomcat/8.5.28
2018-03-12 17:43:20.264  INFO 50560 --- [ost-startStop-1] o.a.catalina.core.AprLifecycleListener   : The APR based Apache Tomcat Native library which allows optimal performance in production environments was not found on the java.library.path: [/Users/kasun/Library/Java/Extensions:/Library/Java/Extensions:/Network/Library/Java/Extensions:/System/Library/Java/Extensions:/usr/lib/java:.]
2018-03-12 17:43:20.348  INFO 50560 --- [ost-startStop-1] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext
2018-03-12 17:43:20.348  INFO 50560 --- [ost-startStop-1] o.s.web.context.ContextLoader            : Root WebApplicationContext: initialization completed in 1229 ms
2018-03-12 17:43:20.479  INFO 50560 --- [ost-startStop-1] o.s.b.w.servlet.ServletRegistrationBean  : Servlet dispatcherServlet mapped to [/]
2018-03-12 17:43:20.482  INFO 50560 --- [ost-startStop-1] o.s.b.w.servlet.FilterRegistrationBean   : Mapping filter: 'characterEncodingFilter' to: [/*]
2018-03-12 17:43:20.483  INFO 50560 --- [ost-startStop-1] o.s.b.w.servlet.FilterRegistrationBean   : Mapping filter: 'hiddenHttpMethodFilter' to: [/*]
2018-03-12 17:43:20.483  INFO 50560 --- [ost-startStop-1] o.s.b.w.servlet.FilterRegistrationBean   : Mapping filter: 'httpPutFormContentFilter' to: [/*]
2018-03-12 17:43:20.483  INFO 50560 --- [ost-startStop-1] o.s.b.w.servlet.FilterRegistrationBean   : Mapping filter: 'requestContextFilter' to: [/*]
2018-03-12 17:43:20.737  INFO 50560 --- [           main] s.w.s.m.m.a.RequestMappingHandlerAdapter : Looking for @ControllerAdvice: org.springframework.boot.web.servlet.context.AnnotationConfigServletWebServerApplicationContext@161cd475: startup date [Mon Mar 12 17:43:19 PDT 2018]; root of context hierarchy
2018-03-12 17:43:20.815  INFO 50560 --- [           main] s.w.s.m.m.a.RequestMappingHandlerMapping : Mapped "{[/hello]}" onto java.lang.String ballerina_sidecar.SpringBootHelloWorld.hello()
2018-03-12 17:43:20.820  INFO 50560 --- [           main] s.w.s.m.m.a.RequestMappingHandlerMapping : Mapped "{[/error]}" onto public org.springframework.http.ResponseEntity<java.util.Map<java.lang.String, java.lang.Object>> org.springframework.boot.autoconfigure.web.servlet.error.BasicErrorController.error(javax.servlet.http.HttpServletRequest)
2018-03-12 17:43:20.821  INFO 50560 --- [           main] s.w.s.m.m.a.RequestMappingHandlerMapping : Mapped "{[/error],produces=[text/html]}" onto public org.springframework.web.servlet.ModelAndView org.springframework.boot.autoconfigure.web.servlet.error.BasicErrorController.errorHtml(javax.servlet.http.HttpServletRequest,javax.servlet.http.HttpServletResponse)
2018-03-12 17:43:20.854  INFO 50560 --- [           main] o.s.w.s.handler.SimpleUrlHandlerMapping  : Mapped URL path [/webjars/**] onto handler of type [class org.springframework.web.servlet.resource.ResourceHttpRequestHandler]
2018-03-12 17:43:20.854  INFO 50560 --- [           main] o.s.w.s.handler.SimpleUrlHandlerMapping  : Mapped URL path [/**] onto handler of type [class org.springframework.web.servlet.resource.ResourceHttpRequestHandler]
2018-03-12 17:43:20.884  INFO 50560 --- [           main] o.s.w.s.handler.SimpleUrlHandlerMapping  : Mapped URL path [/**/favicon.ico] onto handler of type [class org.springframework.web.servlet.resource.ResourceHttpRequestHandler]
2018-03-12 17:43:21.024  INFO 50560 --- [           main] o.s.j.e.a.AnnotationMBeanExporter        : Registering beans for JMX exposure on startup
2018-03-12 17:43:21.074  INFO 50560 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port(s): 8080 (http) with context path ''
2018-03-12 17:43:21.077  INFO 50560 --- [           main] ballerina_sidecar.SpringBootHelloWorld   : Started SpringBootHelloWorld in 2.338 seconds (JVM running for 2.785)

``` 

- Invoke the service through the Sidecar. 

```
curl http://localhost:9090/hello
Hello World, from Spring Boot and Ballerina Sidecar!

```
