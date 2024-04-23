# Install the OpenStack Operator

## Login to the Bastion and cluster if needed

Log into the **lab server** using the **IP** provided in the demo console
and the **lab-user and password** and then ssh to the **bastion host** using the
provided **ssh command** and provided **password**. 

The next step in installing the **OpenStack Operators** will be to login to the cluster using
the **oc* command and *admin* user utilizing the provided password for your demo.

```
oc login -u admin -p <password>
```

1. Create the **openstack-operators** project for the RHOSO operators:

```
oc new-project openstack-operators
```

2. Create the `openstack` project for the deployed RHOSO environment:			

```
oc new-project openstack
```

3. To prevent issues with image signing, enter the following commands and then verify:

```
sudo curl https://www.redhat.com/security/data/f21541eb.txt -o /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-beta
sudo podman image trust set -f /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-beta registry.redhat.io/rhosp-dev-preview
sudo cat /etc/containers/policy.json
```

The policy.json file should look like:
   
```
{
    "default": [
        {
            "type": "insecureAcceptAnything"
        }
    ],
    "transports": {
        "docker": {
            "registry.access.redhat.com": [
                {
                    "type": "signedBy",
                    "keyType": "GPGKeys",
                    "keyPath": "/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release"
                }
            ],
            "registry.redhat.io": [
                {
                    "type": "signedBy",
                    "keyType": "GPGKeys",
                    "keyPath": "/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release"
                }
            ],
            "registry.redhat.io/rhosp-dev-preview": [
                {
                    "type": "signedBy",
                    "keyType": "GPGKeys",
                    "keyPath": "/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-beta"
                }
            ]
        },
        "docker-daemon": {
            "": [
                {
                    "type": "insecureAcceptAnything"
                }
            ]
        }
    }
}
```

### Download and expand the Operator Package Manager (**opm**)

```
wget https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest-4.14/opm-linux.tar.gz
tar -xvzf opm-linux.tar.gz
```

### Use the **opm** tool to create an index image:

Note: You will need to replace **<your_registry>** with the **existing route** of your local
registry or the following information for the registry in your environment.
<your_registry> - quay.apps.uuid.dynamic.redhatworkshops.io

1. Login with your RedHat account and create a secret:
```
podman login registry.redhat.io
podman login registry.redhat.io --authfile auth.json
```

2. Login with quay_user to the environment's registry or login to your own registry and create a secret:
```
podman login --username "quay_user" --password "openstack" quay.apps.uuid.dynamic.redhatworkshops.io/quay_user/dp3-openstack-operator-index
podman login --username "quay_user" --password "openstack" quay.apps.uuid.dynamic.redhatworkshops.io/quay_user/dp3-openstack-operator-index --authfile auth.json
```

or
```
podman login <your_registry> -u <user> -p <password>
podman login <your_registry> -u <user> -p <password> --authfile auth.json
```

3. Create the **image index** and push to the registry:

```
./opm index add -u podman --pull-tool podman --tag quay.apps.uuid.dynamic.redhatworkshops.io/quay_user/dp3-openstack-operator-index:latest -b "registry.redhat.io/rhosp-dev-preview/barbican-operator-bundle:0.1.3-5,registry.redhat.io/rhosp-dev-preview/cinder-operator-bundle:0.1.3-5,registry.redhat.io/rhosp-dev-preview/designate-operator-bundle:0.1.3-5,registry.redhat.io/rhosp-dev-preview/glance-operator-bundle:0.1.3-5,registry.redhat.io/rhosp-dev-preview/heat-operator-bundle:0.1.3-5,registry.redhat.io/rhosp-dev-preview/horizon-operator-bundle:0.1.3-4,registry.redhat.io/rhosp-dev-preview/infra-operator-bundle:0.1.3-5,registry.redhat.io/rhosp-dev-preview/ironic-operator-bundle:0.1.3-3,registry.redhat.io/rhosp-dev-preview/keystone-operator-bundle:0.1.3-5,registry.redhat.io/rhosp-dev-preview/manila-operator-bundle:0.1.3-4,registry.redhat.io/rhosp-dev-preview/mariadb-operator-bundle:0.1.3-4,registry.redhat.io/rhosp-dev-preview/neutron-operator-bundle:0.1.3-4,registry.redhat.io/rhosp-dev-preview/nova-operator-bundle:0.1.3-4,registry.redhat.io/rhosp-dev-preview/octavia-operator-bundle:0.1.3-4,registry.redhat.io/rhosp-dev-preview/openstack-baremetal-operator-bundle:0.1.3-4,registry.redhat.io/rhosp-dev-preview/openstack-operator-bundle:0.1.3-5,registry.redhat.io/rhosp-dev-preview/ovn-operator-bundle:0.1.3-7,registry.redhat.io/rhosp-dev-preview/placement-operator-bundle:0.1.3-4,registry.redhat.io/rhosp-dev-preview/rabbitmq-cluster-operator-bundle:0.1.3-2,registry.redhat.io/rhosp-dev-preview/swift-operator-bundle:0.1.3-4,registry.redhat.io/rhosp-dev-preview/telemetry-operator-bundle:0.1.3-5,registry.redhat.io/rhosp-dev-preview/dataplane-operator-bundle:0.1.3-3,registry.redhat.io/rhosp-dev-preview/openstack-ansibleee-operator-bundle:0.1.3-3" --mode semver
```

```
podman push quay.apps.uuid.dynamic.redhatworkshops.io/quay_user/dp3-openstack-operator-index:latest
```

### Configure the **Catalog Source, OperatorGroup and Subscription** for the **OpenStack Operator**
using your registry:

1. Create secret for the registry:

```
oc create secret generic osp-operators-secret \
    -n openstack-operators \
    --from-file=.dockerconfigjson=auth.json \
    --type=kubernetes.io/dockerconfigjson
```

2. Create the new **CatalogSource, OperatorGroup, and Subscription** CRs
in the **openstack** namespace from **files/openstack-operators.yaml**:

You can cut and paste the referenced yamlfiles from the repo or you may wish to
clone the repository onto the bastion which this guide will assume:

```
git clone https://github.com/rh-osp-demo/dp-demo.git
```

```
cd dp-demo/demo/files
```

Update uuid in all precofigured yaml files with the uuid of your cluster:

```
chmod + replace_uuid.sh && ./replace_uuid.sh <uuid>
```

Apply the preconfigured yaml file for the **osp-ng-openstack-operator.yaml**:

```
oc apply -f osp-ng-openstack-operator.yaml
```

3. Confirm that you have installed the Openstack Operator, **openstack-operator.openstack-operators**: 

```
oc get operators openstack-operator.openstack-operators
```

3. Review the pods in the **openstack-operators** namespace:

```
oc get pods -n openstack-operators
```

[back](prereqs.md) [next](secure.md)
