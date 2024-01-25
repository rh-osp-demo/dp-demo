# Creating the OpenStack Control Plane

We will be using a preconfigured file(files/osp-ng-ctlplane-deploy.yaml) to
create the control plane and at the same time enable the required services,
configure the control plane network, and configure the service back ends. The
bastion has a preconfigured NFS service that we will be using to store glance
images and cinder volumes.

# Create a nfs share for cinder
```
mkdir /nfs/cinder
chmod 777 /nfs/cinder
```

# Configure nfs storage class

```
mkdir /nfs/pv6
mkdir /nfs/pv7
mkdir /nfs/pv8
mkdir /nfs/pv9
mkdir /nfs/pv10
mkdir /nfs/pv11
chmod 777 /nfs/pv*
```
```
oc create -f nfs-storage.yaml
```

# Prepare the secret to place the NFS server connection used by Cinder
```
oc create secret generic cinder-nfs-config --from-file=nfs-cinder-conf
```
# Prepare the secret to place the server connection used by Glance
```
oc create secret generic glance-cinder-conf --from-file=glance-conf
```

# Finally create the OpenStack control plane
```
oc create -f osp-ng-ctlplane-deploy.yaml
```

[back](network-isolation.md) [next](create-dp.md)
