# Configuration, Installation, and Using Red Hat OpenStack Services on OpenShift(RHOSO)

## Default Red Hat OpenStack Platform networks

The following table details the default networks used in a RHOSP deployment. If required, you can update the networks for your environment.

| **Network name** | **VLAN** | **CIDR**            | **NetConfig allocationRange**     | **MetalLB IPAddressPool range** | **nad ipam range**              | **OCP worker nncp range**       
|
|------------------|----------|---------------------|-----------------------------------|---------------------------------|---------------------------------|---------------------------------|
| ctlplane         | n/a      | 192.168.122.0/24    | 192.168.122.100 - 192.168.122.250 | 192.168.122.80 - 192.168.122.90 | 192.168.122.30 - 192.168.122.70 | 192.168.122.10 - 
192.168.122.20 |
| external         | n/a      | 10.0.0.0/24         | 10.0.0.100 - 10.0.0.250           | n/a                             | n/a                             | n/a                             
|
| internalapi      | 20 	      | 172.17.0.0/24       | 172.17.0.100 - 172.17.0.250       | 172.17.0.80 - 172.17.0.90       | 172.17.0.30 - 172.17.0.70       | 172.17.0.10 - 
172.17.0.20       |
| storage 	         | 21 	      | 172.18.0.0/24 	      | 172.18.0.100 - 172.18.0.250 	      | 172.18.0.80 - 172.18.0.90       | 172.18.0.30 - 172.18.0.70       | 172.18.0.10 
- 172.18.0.20       |
| tenant           | 22       | 172.19.0.0/24       | 172.19.0.100 - 172.19.0.250       | 172.19.0.80 - 172.19.0.90       | 172.19.0.30 - 172.19.0.70       | 172.19.0.10 - 172.19.0.20       
|
| storageMgmt 	     | 23 		      | 172.20.0.0/24 	      | 172.20.0.100 - 172.20.0.250       | 172.20.0.80 - 172.20.0.90       | 172.20.0.30 - 172.20.0.70       | 
172.20.0.10 - 172.20.0.20       |

## Preparing RHOCP for RHOSP network isolation

1. Retrieve the names of the worker nodes in the RHOCP cluster:
`oc get nodes -l node-role.kubernetes.io/worker -o jsonpath="{.items[*].metadata.name}"`

2. Discover the network configuration of the OCP nodes using the **worker node names**:

`oc get nns/<worker_node> -o yaml | more`

3. Create **openstack-nncp.yaml** to configure a **NodeNetworkConfigurationPolicy (nncp) CR** on your workstation
using the **ens5 interface** from the previous command.

apiVersion: nmstate.io/v1
kind: NodeNetworkConfigurationPolicy
metadata:
  name: osp-ens5-<worker_node>
spec:
  desiredState:
    interfaces:
    - description: internalapi vlan interface
      ipv4:
        address:
        - ip: 172.17.0.10
          prefix-length: 24 
        enabled: true
        dhcp: false
      ipv6:
        enabled: false
      name: ens5.20
      state: up
      type: vlan
      vlan:
        base-iface: ens5
        id: 20
    - description: storage vlan interface
      ipv4:
        address:
        - ip: 172.18.0.10
          prefix-length: 24 
        enabled: true
        dhcp: false
      ipv6:
        enabled: false
      name: ens5.21
      state: up
      type: vlan
      vlan:
        base-iface: ens5
        id: 21
    - description: tenant vlan interface
      ipv4:
        address:
        - ip: 172.19.0.10
          prefix-length: 24 
        enabled: true
        dhcp: false
      ipv6:
        enabled: false
      name: ens5.22
      state: up
      type: vlan
      vlan:
        base-iface: ens5
        id: 22
    - description: control plane interface
      ipv4:
        address:
        - ip: 192.168.122.10
          prefix-length: 24 
        enabled: true
        dhcp: false
      ipv6:
        enabled: false
      mtu: 1500
      name: ens5
      state: up
      type: ethernet
  nodeSelector:
    kubernetes.io/hostname: <worker_node>
    node-role.kubernetes.io/worker: ""

4. Create the **nncp CR** in the cluster:

`oc apply -f openstack-nncp.yaml`

5. Verify that the **nncp CR** is created:

`oc get nncp -w`

[back](secure.md) [next](configure-cp.md)
