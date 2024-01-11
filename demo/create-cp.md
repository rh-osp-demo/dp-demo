# Creating the OpenStack Control Plane

We will be using a preconfigured file(files/osp-ng-ctlplane-deploy.yaml) to
create the control plane and at the same time enable the required services,
configure the control plane network, and configure the service back ends.

oc create -f osp-ng-ctlplane-deploy.yaml


[back](network-isolation.md) [next](create-dp.md)
