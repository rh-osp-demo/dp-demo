## Preparing RHOCP for RHOSP network isolation

We will be using a preconfigured set of yaml files in the **files** directory which
start with **osp-ng-nncp-**.

If not already in the **files directory**:

```
cd dp-demo/demo/files
```

1. The preconfigured yamls will be applied indivdually:

```
oc apply -f osp-ng-nncp-w1.yaml
oc apply -f osp-ng-nncp-w2.yaml
oc apply -f osp-ng-nncp-w3.yaml
```

Wait until they are in an available state before proceeding:

```
oc get nncp -w
```

```
NAME                              STATUS      REASON
osp-enp1s0-worker-ocp4-worker1    Available   SuccessfullyConfigured
osp-enp1s0-worker-ocp4-worker2    Available   SuccessfullyConfigured
osp-enp1s0-worker-ocp4-worker3    Available   SuccessfullyConfigured
```

2.Before proceeding we will configure  a **nad** resource for each isolated network to
attach a service pod to the network:

```
oc apply -f osp-ng-netattach.yaml
```

3. Once the nodes are available and attached we will configure the **MetalLB IP address range** using
a preconfigured yaml file:

```
oc apply -f osp-ng-metal-lb-ip-address-pools.yaml
```

4. Lastly, we will configure a **L2Advertisement** resource which will define which node advertises a
service to the local network which has been preconfigured for your demo environment:

```
oc apply -f osp-ng-metal-lb-l2-advertisements.yaml
```

5. Configure the Dataplane Network using a preconfigured yaml file(**files/osp-ng-dataplane-netconfig.yaml**)
which will configure the topology for each data plane network.

```
oc apply -f osp-ng-dataplane-netconfig.yaml
```

6. If your cluster is RHOCP 4.14 or later and it has OVNKubernetes as the network back end, then you must enable global forwarding so that MetalLB can work on a secondary network interface.

Check the network back end used by your cluster:

```
$ oc get network.operator cluster --output=jsonpath='{.spec.defaultNetwork.type}'
```
If the back end is OVNKubernetes, then run the following command to enable global IP forwarding:

```
$ oc patch network.operator cluster -p '{"spec":{"defaultNetwork":{"ovnKubernetesConfig":{"gatewayConfig":{"ipForwarding": "Global"}}}}}' --type=merge
```

[back](secure.md) [next](create-cp.md)
