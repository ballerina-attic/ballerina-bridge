Scenario I : Ballerina with existing Service Mesh




Pre-req
- K8s
- Istio

Steps:

1. Build and push Ballerina docker image.
2. Manual sidecar injection and deploying to K8s
  - Kube Injection : istioctl kube-inject -f ballerina_restful_svc.yaml -o ballerina_restful_svc_istio_injected.yaml
  - Deploy on k8s: kubectl apply -f ballerina_restful_svc_istio_injected.yaml or kubectl apply -f <(istioctl kube-inject -f ballerina_restful_svc.yaml)


Scenario/Guides
- Ballerina RESTful service with Istio
    - Basic installation and simple routing rules applied on RESTful service.
- Modified Bookinfo scenario (Istio's main sample https://istio.io/docs/guides/bookinfo.html) with some services implemented with Ballerina.
    - Showcase composite service development capabilities and how Ballerina works with Istio ecosystem (observability, service discovery etc.)
