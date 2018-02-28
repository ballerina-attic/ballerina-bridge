# Ballerina with Istio Service Mesh

This example deomstrate how you can run a Ballerina program with Istio service mesh. 

## Prerequisites 
- Istio Service Mesh ([Setting up Istio](https://istio.io/docs/setup/kubernetes/)).



##Steps

Following are the key steps involved in running your Ballerina program with Istio Service Mesh. 

1. Build and push the docker image that contains your Ballerina services.  
2. Create the deployment descriptor for your 
3. Manual sidecar injection and deploying to K8s
   
   `istioctl kube-inject -f ballerina_restful_svc.yaml -o ballerina_restful_svc_istio_injected.yaml` 
4. Deploy on K8s. 

   `kubectl apply -f ballerina_restful_svc_istio_injected.yaml` 
5. Now the Ballerina service is successfully deployed into your Istio service mesh and you can get the Gateway URL 
as mentioned in [here](https://istio.io/docs/guides/bookinfo.html) and invoke the service using following curl command. 

   `kcurl http://$GATEWAY_URL/ballerina` 

