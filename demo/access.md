# Access the OpenStack

1. From the **bastion server** access the Control Plane

```
oc rsh -n openstack openstackclient
```

On Control Plane verify OpenStack:
```
cd /home/cloud-admin
openstack compute service list
openstack network agent list
logout
```

[back](create-dp.md) [start](index.md)
