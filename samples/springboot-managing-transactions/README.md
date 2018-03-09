# Distributed Transactions with SpringBoot  



- Travel Mgt Service Req 

`` curl -v -X POST -d '{ "travel_type":"vacation", "full_name":"John Doe", "departure_city":"SF","destination_city":"Paris", "state_date":"2018-03-20T00:00:00.000Z", "end_date":"2018-03-30T00:00:00.000Z", "airline":"delta", "hotel":"hilton"}' \
 "http://localhost:8000/travel/reservation" -H "Content-Type:application/json"  ``