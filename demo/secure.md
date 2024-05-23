# Providing secure access to the Red Hat OpenStack Platform services

1. We will be utilizing a preconfigured yaml file(**files/osp-ng-ctlplane-secret.yaml**)
to create a seperate base64 password for heat and one for the remaining
services.

```
oc create -f osp-ng-ctlplane-secret.yaml
```

2. Verify the **Secret** was created:

```
oc describe secret osp-secret -n openstack
```
3. Create the libvirt **Secret**:
```
oc create -f osp-ng-libvirt-secret.yaml
```
4. Verify the libvirt **Secret** was created:

```
oc describe secret libvirt-secret -n openstack
```

[back](install-operators.md) [next](network-isolation.md)
