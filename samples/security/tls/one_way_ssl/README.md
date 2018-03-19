
# Enabling one-way SSL for Spring Boot service

1. Run HelloWorld Spring Boot service. 
2. Run sidecar for one-way SSL`` ballerina run ballerina/sidecar/security/tls/one_way_ssl``.  
3. Invoke service via HTTPs. 
`` curl -k https://localhost:9095/hello ``






