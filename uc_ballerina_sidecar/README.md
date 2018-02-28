

Scenario III : Ballerina as a generic Sidecar

- Wrap non-ballerina code with Ballerina Sidecar and both are deployed in the same pod.

- Implement non-ballerina service without outbound network application functions (CB, timeouts) or transactions aware capabilities.
- All such capabilities are implement at the Ballerina sidecar.
- Bundle them in the same pod and deploy. 
