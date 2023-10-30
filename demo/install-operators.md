# Configuration, Installation, and Using Red Hat OpenStack Services on OpenShift(RHOSO)

##Install the Prerequisite Operators

There are two operators that are required to be installed before you can install
the OpenStack Operator, the [NMState 
Operator](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.13/html/networking/kubernetes-nmstate#installing-the-kubernetes-nmstate-operator-cli)
and the [MetalLB 
Operator](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.13/html/networking/load-balancing-with-metallb#nw-metallb-installing-operator-cli_metallb-operator-install) 

### Installing the Operators from the Operator Hub

#### Logging in to the Cluster

Use the URL for the console and the password for the admin user provided in the
demo console.

##### NMState Operator

1. Click on **Operators** to expand the section and then select "OperatorsHub".
2. Search for **NMState** and select **Kubernetes NMState Operator** and click **Install**
3. Use defaults and click **Install**

#### MetalLB Operator

1. Click on **Operators** to expand the section and then select "OperatorsHub".
2. Search for **MetalLB** and select **MetalLB Operator** and click **Install**
3. Use defaults and click **Install**

### Installating the Prerequisite Operators using the CLI

#### Logging in to the Cluster

Log into the **Bastion server** using the **ssh command** provided in the demo console
and the **lab-user password**.

The next step in installing the Operators will be to login to the cluster using
the **oc* command and *admin* user utilizing the provided password for your demo.

`oc login -u admin -p <password>`

##### NMState Operator

1. Create the **nmstate** Operator namespace:

`cat << EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  labels:
    kubernetes.io/metadata.name: openshift-nmstate
    name: openshift-nmstate
  name: openshift-nmstate
spec:
  finalizers:
  - kubernetes
EOF`

2. Create the **OperatorGroup**:

`cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  annotations:
    olm.providedAPIs: NMState.v1.nmstate.io
  name: openshift-nmstate
  namespace: openshift-nmstate
spec:
  targetNamespaces:
  - openshift-nmstate
EOF`

3. Confirm the OperatorGroup is installed in the namespace:

`oc get operatorgroup -n openshift-nmstate`

4. Subscribe to the **nmstate** Operator:

`cat << EOF| oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  labels:
    operators.coreos.com/kubernetes-nmstate-operator.openshift-nmstate: ""
  name: kubernetes-nmstate-operator
  namespace: openshift-nmstate
spec:
  channel: stable
  installPlanApproval: Automatic
  name: kubernetes-nmstate-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF`

5. Create instance of the **nmstate** operator:

`cat << EOF | oc apply -f -
apiVersion: nmstate.io/v1
kind: NMState
metadata:
  name: nmstate
EOF`

6. Confirm that the deployment for the **nmstate** operator is running:

`oc get clusterserviceversion -n openshift-nmstate \
 -o custom-columns=Name:.metadata.name,Phase:.status.phase`

##### MetalLB Operator

1. Create the **MetalLB** Operator namespace:

`cat << EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: metallb-system
EOF`

2. Create the **OperatorGroup**:

`cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: metallb-operator
  namespace: metallb-system
EOF`

3. Confirm the OperatorGroup is installed in the namespace:

`oc get operatorgroup -n metallb-system`

4. Subscribe to the **metallb** Operator:

`cat << EOF| oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: metallb-operator-sub
  namespace: metallb-system
spec:
  channel: stable
  name: metallb-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF`

5. Confirm the **metallb** installplan is in the namespace:

`oc get installplan -n metallb-system`

6. Confirm the **metallb** operator is installed:

`oc get clusterserviceversion -n metallb-system \
 -o custom-columns=Name:.metadata.name,Phase:.status.phase`

7. Create a single instance of a **metallb** resource:

`cat << EOF | oc apply -f -
apiVersion: metallb.io/v1beta1
kind: MetalLB
metadata:
  name: metallb
  namespace: metallb-system
EOF`

8. Verify that the deployment for the controller is running:

`oc get deployment -n metallb-system controller`

9. Verify that the daemon set for the speaker is running:

`oc get daemonset -n metallb-system speaker`

## Install the OpenStack Operator

### Create a **QuayRegistry** in your Demo environment if needed

1. Using the **Red Hat Quay** URL for your environment log in as
**quayadmin** using the provided password
2. Click on **Create New Repository** and name it **rhosp-dev-preview**
3. Leave as Private and click **Create Private Repository**

### Login to the Bastion and cluster if needed

Log into the **Bastion server** using the **ssh command** provided in the demo console
and the **lab-user password**.

The next step in installing the Operators will be to login to the cluster using
the **oc* command and *admin* user utilizing the provided password for your demo.

`oc login -u admin -p <password>`

### Installing the OpenStack Operator

1. Create the **openstack-operators** project for the RHOSO operators:

`oc new-project openstack-operators`

2. Create the `openstack` project for the deployed RHOSO environment:			

`oc new-project openstack`

3. To prevent issues with image signing, enter the following commands and then verify:

`sudo curl https://www.redhat.com/security/data/f21541eb.txt -o /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-beta`

`sudo podman image trust set -f /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-beta registry.redhat.io/rhosp-dev-preview`

`sudo cat /etc/containers/policy.json`

The policy.json file should look like:
   
`{
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
}`

4. Download and expand the Operator Package Manager (**opm**)

`wget https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/opm-linux.tar.gz`

`tar -xvf opm-linux.tar.gz`

5. Use the **opm** tool to create an index image:

Note: You will need to replace **<your_registry>** with the **existing route** of your local
registry or the Red Hat Quay instance in your environment.

6. Login with your RedHat account:
`podman login registry.redhat.io`

7. Login with quayadmin to the environment's Quay or login to your own registry:
`podman login <your_registry> --authfile auth.json`

8. Create secret for the registry:
`podman login --username "quayadmin" --password <password> <your_registry> --authfile auth.json
oc create secret generic osp-operators-secret \
    -n openstack-operators \
    --from-file=.dockerconfigjson=auth.json \
    --type=kubernetes.io/dockerconfigjson`

9. `./opm index add -u podman --pull-tool podman --tag <your_registry>:<port>/quayadmin/rhosp-dev-preview/openstack-operator-index:0.1.0 -b 
"registry.redhat.io/rhosp-dev-preview/openstack-operator-bundle:0.1.0,registry.redhat.io/rhosp-dev-preview/swift-operator-bundle:0.1.0,registry.redhat.io/rhosp-dev-preview/glance-operator-bundle:0.1.0,registry.redhat.io/rhosp-dev-preview/infra-operator-bundle:0.1.0,registry.redhat.io/rhosp-dev-preview/ironic-operator-bundle:0.1.0,registry.redhat.io/rhosp-dev-preview/keystone-operator-bundle:0.1.0,registry.redhat.io/rhosp-dev-preview/ovn-operator-bundle:0.1.0,registry.redhat.io/rhosp-dev-preview/placement-operator-bundle:0.1.0,registry.redhat.io/rhosp-dev-preview/telemetry-operator-bundle:0.1.0,registry.redhat.io/rhosp-dev-preview/heat-operator-bundle:0.1.0,registry.redhat.io/rhosp-dev-preview/cinder-operator-bundle:0.1.0,registry.redhat.io/rhosp-dev-preview/manila-operator-bundle:0.1.0,registry.redhat.io/rhosp-dev-preview/neutron-operator-bundle:0.1.0,registry.redhat.io/rhosp-dev-preview/nova-operator-bundle:0.1.0,registry.redhat.io/rhosp-dev-preview/openstack-ansibleee-operator-bundle:0.1.0,registry.redhat.io/rhosp-dev-preview/mariadb-operator-bundle:0.1.0,registry.redhat.io/rhosp-dev-preview/openstack-baremetal-operator-bundle:0.1.0,registry.redhat.io/rhosp-dev-preview/rabbitmq-cluster-operator-bundle:0.1.0,registry.redhat.io/rhosp-dev-preview/rabbitmq-cluster-operator-bundle:0.1.0,registry.redhat.io/rhosp-dev-preview/dataplane-operator-bundle:0.1.0,registry.redhat.io/rhosp-dev-preview/horizon-operator-bundle:0.1.0" --mode semver`.

`podman push <your_registry>/quayadmin/rhosp-dev-preview/openstack-operator-index:0.1.0`

#### Configure the **Catalog Source, OperatorGroup and Subscription** for the **OpenStack Operator**
using your registry:

1. Create the new **CatalogSource, OperatorGroup, and Subscription** CRs
in the **openstack** namespace in **openstack-operators.yaml**:

apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: openstack-operator-index
  namespace: openstack-operators
spec:
  sourceType: grpc
  secrets:
    - osp-operators-secret
  image: <your_registry>/<account>/rhosp-dev-preview/openstack-operator-index:0.1.0
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openstack
  namespace: openstack-operators
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openstack-operator
  namespace: openstack-operators
spec:
  name: openstack-operator
  channel: alpha
  source: openstack-operator-index
  sourceNamespace: openstack-operators

2. Confirm that you have installed the Openstack Operator, **openstack-operator.openstack-operators**: 

`oc get operators openstack-operator.openstack-operators`

3. Review the pods in the **openstack-operators** namespace:

`oc get pods -n openstack-operators`

[back](prereqs.md) [next](secure.md)
