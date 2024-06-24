# Scale out your deployment with a Metal3/Baremetal Cluster Operator provisioned node

1. In the **hypervisor** server, create an additional empty virtual machine to host the second compute host:

```
sudo -i
cd /var/lib/libvirt/images
qemu-img create -f qcow2 /var/lib/libvirt/images/osp-compute-1.qcow2 150G
virt-install --virt-type kvm --ram 6144 --vcpus 2 --cpu=host-passthrough --os-variant rhel8.4 --disk path=/var/lib/libvirt/images/osp-compute-1.qcow2,device=disk,bus=virtio,format=qcow2 --network network:ocp4-provisioning,mac="de:ad:be:ef:00:07" --network network:ocp4-net --boot hd,network --noautoconsole --vnc --name osp-compute1 --noreboot
virsh start osp-compute1
```

2. Add the new host in the virtualbmc tool so that it can be managed via IPMI

```
iptables -A LIBVIRT_INP -p udp --dport 6237 -j ACCEPT
vbmc add --username admin --password redhat --port 6237 --address 192.168.123.1 --libvirt-uri qemu:///system osp-compute1
vbmc start osp-compute1
```

The new host should be visible:
```
[root@hypervisor ~]# vbmc list
+--------------+---------+---------------+------+
| Domain name  | Status  | Address       | Port |
+--------------+---------+---------------+------+
| ocp4-bastion | running | 192.168.123.1 | 6230 |
| ocp4-master1 | running | 192.168.123.1 | 6231 |
| ocp4-master2 | running | 192.168.123.1 | 6232 |
| ocp4-master3 | running | 192.168.123.1 | 6233 |
| ocp4-worker1 | running | 192.168.123.1 | 6234 |
| ocp4-worker2 | running | 192.168.123.1 | 6235 |
| ocp4-worker3 | running | 192.168.123.1 | 6236 |
| osp-compute1 | running | 192.168.123.1 | 6237 |
+--------------+---------+---------------+------+
```

Back on the **bastion** server:

3. Create a Baremetal Host to prepare
```
oc apply -f osp-ng-osp-compute1-bmh.yaml -n openshift-machine-api
```

4. Wait until the baremal host is in Available state. The bmh will move first to registering, then to inspecting and finally to available state. This process could take around 4 min.
```
oc get bmh -n openshift-machine-api -w

Desired output:

oc get bmh -n openshift-machine-api
NAME           STATE                    CONSUMER                   ONLINE   ERROR   AGE
master1        externally provisioned   ocp-49jkw-master-0         true             12h
master2        externally provisioned   ocp-49jkw-master-1         true             12h
master3        externally provisioned   ocp-49jkw-master-2         true             12h
osp-compute1   available                                           false            7m39s
worker1        provisioned              ocp-49jkw-worker-0-k9rl2   true             12h
worker2        provisioned              ocp-49jkw-worker-0-xm9fs   true             12h
worker3        provisioned              ocp-49jkw-worker-0-czfxj   true             12h
```
Note: please control + C to quit the waiting command

5. Label the baremetal host with **app:openstack** so that it can be used by the openstackbaremetalset CR:
```
oc label BareMetalHost osp-compute1 -n openshift-machine-api app=openstack
```

6. Deploy the Dataplane

Replace uuid in osp-ng-dataplane-node-set-deploy-scale-out.yaml and edit the edpm_bootstrap_command with your subscription-manager credentials. Finally apply:
```
oc apply -f osp-ng-dataplane-node-set-deploy-scale-out.yaml
oc apply -f osp-ng-dataplane-deployment-scale-out.yaml
```

7. A provisioner pod will be executed to pull out the edpm RHEL image and to provison in the node:

```
oc get pods -n openstack
NAME                                                              READY   STATUS      RESTARTS   AGE
[...]
reboot-os-openstack-edpm-ipam-openstack-edpm-ipam-scqq9           0/1     Completed   0          111m
run-os-openstack-edpm-ipam-openstack-edpm-ipam-zs4dk              0/1     Completed   0          111m
scale-out-provisioned-provisionserver-openstackprovisionse2csnp   1/1     Running     0          2m18s
ssh-known-hosts-openstack-edpm-ipam-67lt8                         0/1     Completed   0          111m
validate-network-openstack-edpm-ipam-openstack-edpm-ipam-r22jq    0/1     Completed   0          112m
[...]
```

8. Node will move from available to provisioning:
```
oc get bmh -n openshift-machine-api
```

After node provioning the deployment will proceed similarly as in the pre-provisoned section:

You can view the Ansible logs while the deployment executes:

```
oc logs -l app=openstackansibleee -f --max-log-requests 10
```

.Sample Output
```
(...)
PLAY RECAP *********************************************************************
edpm-compute-1             : ok=53   changed=26   unreachable=0    failed=0    skipped=54   rescued=0    ignored=0
```

Ctrl-C to exit.

Verify that the data plane is deployed.

NOTE: This takes several minutes.

```
oc get openstackdataplanedeployment
```

Repeat the query until you see the following:

.Sample Output
```
NAME                  STATUS   MESSAGE
openstack-scale-out-provisioned   True     Setup Complete
```

```
oc get openstackdataplanenodeset
```

Repeat the query until you see the following:

```
NAME                  STATUS   MESSAGE
scale-out-provisioned   True     NodeSet Ready
```

If you need to access to your provisioned compute node:

Get the ipsets in the openstack namespace

```
oc get ipset -n openstack
NAME             READY   MESSAGE          RESERVATION
edpm-compute-0   True    Setup complete
edpm-compute-1   True    Setup complete
```

Describe the provisioned node **edpm-compute-1**:
```
oc describe ipset edpm-compute-1 -n openstack
```

You will get controlplane address in the reservation properties:

Output
```
[...]
  Observed Generation:     1
  Reservations:
    Address:     172.22.0.101
    Cidr:        172.22.0.0/24
    Dns Domain:  ctlplane.aio.example.com
    Gateway:     172.22.0.1
    Mtu:         1500
    Network:     ctlplane
    Routes:
      Destination:  0.0.0.0/0
      Nexthop:      172.22.0.1
[...]
```

Finally, you can ssh to the edp-compute1 using the address from the previous output:

```
ssh -i /root/.ssh/id_rsa_compute cloud-admin@172.22.0.101
```

[back](access.md) [start](index.md)
