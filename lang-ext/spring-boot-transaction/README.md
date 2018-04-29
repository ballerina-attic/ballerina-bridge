# Spring Boot Transaction Extension

This module provides required extensions for Spring Boot Service to work 
seamlessly with Ballerina micro-transaction.

In Ballerina, we support managing transactions across multiple micro services
. In order to enable micro transaction support in Spring Boot services which 
plugged in to Ballerina eco-system, we developed custom transaction manager 
and service interceptor.
 
 ## How to add Ballerina Spring Boot Transaction Extension to your service  
 
 Following steps need to be done to enable micro transaction support for 
 Spring Boot service in Ballerina eco-system.
 * Build the [Spring Boot transaction extension](https://github.com/ballerina-platform/ballerina-bridge/tree/master/lang-ext/spring-boot-transaction) locally using `mvn clean install`.  
 
 * Add below dependencies to the service `pom.xml` file.
 
 ```xml
    <dependencies>
      <dependency>
          <groupId>io.ballerina.springboot</groupId>
          <artifactId>ballerina-txn-common</artifactId>
          <version>0.970-SNAPSHOT</version>
      </dependency>
      <dependency>
          <groupId>io.ballerina.springboot</groupId>
          <artifactId>ballerina-txn-jdbc</artifactId>
          <version>0.970-SNAPSHOT</version>
      </dependency>
        ...
    </dependencies>
 ```
 Spring Boot service implementation needs to mark as transactional. This can 
 be either declarative transactional or programmatic transactional.
 
 * Register callback service(`io.ballerina.springboot
 .TransactionCallbackService`) along with other services.
 
 for example, If your service is `BookingService`, register both 
 `BookingService` and `TransactionCallbackService` in Spring application like
  below,
  
  ```java
      public static void main(String[] args) {
          SpringApplication.run(new Class[]{BookingService.class, TransactionCallbackService.class}, args);
      }  
  ```
Note: With current implementation, user needs to register callback 
service manually. We are working on automatically register when registering 
other services.
 