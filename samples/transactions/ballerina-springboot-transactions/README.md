# Distributed Transactions with Ballerina Bridge and Spring Boot 


## Use case
This sample demonstrate the distributed transaction capabilities of Ballerina Bridge. When you have to define distributed transaction boundaries and integrate Ballerina services with non-Ballerina service (such as Spring Boot), you can you Ballerina Bridge to acheive that. 

![Ballerina Distributed Transactions with Spring Boot](images/transactions.png "Ballerina Distributed Transactions with Spring Boot")
 
In this example, we have a travel management service which books the airline and hotel based on the requested dates and destination. Therefore the travel management service invokes the hotel and airline services. All of these operations needs to be executed in a single transaction (i.e. if either the airline or hotel service booking is failed, then all the other bookings should be cancelled.)
Hence the transaction boundary spans accross multiple services.  

The travel management service is built using Ballerina and initiate the transaction (i.e. Initiator) between hotel and airline service. Hotel service is a non-Ballerina service which is built using Spring Boot and it takes to a mysql database. The airline service is another Ballerina service. 



## Implementation 

In the travel management service we define the hotel and airline service invocation in a single tranasnal block. 
```ballerina
transaction { 
    ... 
    hotelRes = check participantHotelService -> post("/reservation/hotel", request = hotelReq);
    if (airlhotelRes.statusCode != 200) { 
        ...
        abort;
    }
    ... 
    airlineRes = check participantAirlineService -> post("/airline/reservation", request = req);
    if (hotelRes.statusCode != 200) { 
        ...
        abort;
    }
    ...
 }
```

The hotel service does not understand the transactions initiator by Ballerina. Hence it has to be invoked via the Ballerina Bridge, which will take care of the transaction handling capabilities of the hotel service. Here it acts as a participant of the distributed transaction. 
To propagate transactions all the way down to the database level you need to include the Ballerina Spring extensions in the your Spring Boot service . You can refer this for more details.
When it comes to the deployment, we'll deploy the Ballerina Bridge and Hotel service in the same pod or VM.  
  That's all you have to do to make your Spring Boot service a part of the distributed transaction. 

Airline service is a Ballerina service, which will also be another participant. The transaction logic of the airline service contains the conditions to rollback the transactions when something goes wrong. 
```ballerina
transaction {
    // if the request is not for the specified airline, then it will call 'abort' to rollback the transaction. 
}
```

 
### Running service on Kubernetes 
All the required deployment artifacts to run this sample on Kubernetes are included along with each service. 

- Travel Management Service (Initiator)

Navigate to ``ballerina-bridge/samples/transactions/ballerina-springboot-transactions/travel_mgt_service_ballerina`` directory and execute: 
```
    $kubectl apply -f kubernetes
```
You should be able to see all artifacts getting deployed successfully. 


- Hotel Service 

It's recommended to deploy hotel Spring Boot service and Ballerina Bridge in the same pod, so that Ballerina Bridge acts as a side car. 
Since the hotel service uses mysql database, you need to deploy the mysql service using ``/ballerina-bridge/samples/transactions/ballerina-springboot-transactions/hotel_service_springboot/db_setup/kubernetes`` artifacts. 
Navigate to that directory and execute: 

```
    $kubectl apply -f kubernetes
```

Then you can deploy the Hotel Spring Boot service alongside the Ballerina Bridge sidecar using Kubernetes artifacts in ``ballerina-bridge/samples/transactions/ballerina-springboot-transactions/bridge``. 

```
    $kubectl apply -f kubernetes
```
Here we are deploying a single pod with two containers; Spring Boot service and Ballerina Bridge. Please refer `` ballerina_bridge_sidecar_deployment.yaml`` more details on the deployment. 



- Airline Service 
This is a Ballerina service which you can deploy using the deployment scripts in `` ballerina-bridge/samples/transactions/ballerina-springboot-transactions/airline_service_ballerina/kubernetes``. 

`` $$kubectl apply -f kubernetes``

 ### Testing 
Successful Scenario 
``` 
curl -X POST -d '{ "full_name": "John Doe", "departure_city": "San Francisco", "destination_city": "Paris", "start_date": "2018-03-20T00:00:00.000Z", "end_date": "2018-03-30T00:00:00.000Z", "airline": "delta", "hotel": "hilton" }'  "http://travelmgt.sample.bridge.io/travel" -H "Content-Type:application/json"

Response: 
{"status":"Airline and Hotel reservations successful!"}
```

Failure in Airline service 
```
curl -X POST -d '{ "full_name": "Richard Roe", "departure_city": "San Francisco", "destination_city": "Paris", "start_date": "2018-03-20T00:00:00.000Z", "end_date": "2018-03-30T00:00:00.000Z", "united": "delta", "hotel": "hilton" }'  "http://travelmgt.sample.bridge.io/travel" -H "Content-Type:application/json"

Response:
{"status":" : Hotel Reservation Failed"}

```

Failure in Hotel service 
```
curl -X POST -d '{ "full_name": "Jane Roe1111111111111", "departure_city": "San Francisco", "destination_city": "Paris", "start_date": "2018-03-20T00:00:00.000Z", "end_date": "2018-03-30T00:00:00.000Z", "airline": "delta", "hotel": "hilton" }'  "http://travelmgt.sample.bridge.io/travel" -H "Content-Type:application/json"

Response : 
{"status":" : Hotel Reservation Failed"}
```





