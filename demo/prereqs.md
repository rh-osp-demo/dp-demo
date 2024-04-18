# Configuration, Installation, and Using Red Hat OpenStack Services on OpenShift

## Prerequisites for installation

Some prerequisites needed to install Red Hat OpenStack Services on OpenShift(RHOSO) are
already included in the demonstration environment such as:

- An operational OpenShift cluster running 4.13 which supports Multus CNI
- oc command line tool on your workstation(bastion host) 
- podman command line tool on your workstation(bastion host) 
- Access to repositories which contain the Dev Preview code
- Access to an existing registry or create a local Quay registry
- Example YAML files are available in this repository which can be cloned or
copy and pasted for use. For ease of instructions it will be assumed the repo
has been cloned

### Install the Prerequisite Operators

There are three operators that are required to be installed before you can install
the OpenStack Operator, the [NMState 
Operator](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.13/html/networking/kubernetes-nmstate#installing-the-kubernetes-nmstate-operator-cli)
the [MetalLB 
Operator](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.13/html/networking/load-balancing-with-metallb#nw-metallb-installing-operator-cli_metallb-operator-install) 
and the [Cert-Manager  
Operator](https://docs.openshift.com/container-platform/4.14///security/cert_manager_operator/cert-manager-operator-install.html)

#### Installing the Operators from the Operator Hub

##### Logging in to the Cluster

Use the URL for the console and the password for the admin user provided in the
demo console.

##### NMState Operator

1. Click on **Operators** to expand the section and then select "OperatorsHub".
2. Search for **NMState** and select **Kubernetes NMState Operator** and click **Install**
3. Use defaults and click **Install**

###### Create a **NMState Instance**

1. In **Details** Click on **Create Instance** under the **NMState API**
2. Use defaults and click **Create**

##### MetalLB Operator

1. Click on **Operators** to expand the section and then select "OperatorsHub".
2. Search for **MetalLB** and select **MetalLB Operator** and click **Install**
3. Use defaults and click **Install**

###### Create a **MetalLB Instance**

1. In **Details** Click on **Create Instance** under the **MetalLB API**
2. Use defaults and click **Create**

##### Cert Manager Operator

1. Click on **Operators** to expand the section and then select "OperatorsHub".
2. Search for **cert-manager** and select **cert-manager Operator for Red Hat OpenShift** and click **Install**
3. Select version **stable-v1.12** and use the other defaults and click **Install**

##### Prepare the registry:

1. On the **bastion host** confirm the **OperatorGroup** is installed in the namespace:

```
oc get operatorgroup -n cert-manager-operator
```

2. Confirm the **cert-manager** installplan is in the namespace:

```
oc get installplan -n cert-manager-operator
```

3. Confirm the **cert-manager** operator is installed:

```
oc get clusterserviceversion -n cert-manager-operator \
 -o custom-columns=Name:.metadata.name,Phase:.status.phase
```

4. Verify that cert-manager pods are up and running by entering the following command:

```
oc get pods -n cert-manager
```

#### Installing the Prerequisite Operators using the CLI

##### Logging in to the Cluster

Log into the **Bastion server** using the **ssh command** provided in the demo console
and the **lab-user password**.

The next step in installing the Operators will be to login to the cluster using
the **oc* command and *admin* user utilizing the provided password for your demo.

`oc login -u admin -p <password>`

##### NMState Operator

1. Create the **nmstate** Operator namespace:

```
cat << EOF | oc apply -f -
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
EOF
```

2. Create the **OperatorGroup**:

```
cat << EOF | oc apply -f -
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
EOF
```

3. Confirm the OperatorGroup is installed in the namespace:

```
oc get operatorgroup -n openshift-nmstate
```

4. Subscribe to the **nmstate** Operator:

```
cat << EOF| oc apply -f -
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
EOF
```

5. Create instance of the **nmstate** operator:

```
cat << EOF | oc apply -f -
apiVersion: nmstate.io/v1
kind: NMState
metadata:
  name: nmstate
EOF
```

6. Confirm that the deployment for the **nmstate** operator is running:

```
oc get clusterserviceversion -n openshift-nmstate \
 -o custom-columns=Name:.metadata.name,Phase:.status.phase
```

##### MetalLB Operator

1. Create the **MetalLB** Operator namespace:

```
cat << EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: metallb-system
EOF
```

2. Create the **OperatorGroup**:

```
cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: metallb-operator
  namespace: metallb-system
EOF
```

3. Confirm the OperatorGroup is installed in the namespace:

```
oc get operatorgroup -n metallb-system
```

4. Subscribe to the **metallb** Operator:

```
cat << EOF| oc apply -f -
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
EOF
```

5. Confirm the **metallb** installplan is in the namespace:

```
oc get installplan -n metallb-system
```

6. Confirm the **metallb** operator is installed:

```
oc get clusterserviceversion -n metallb-system \
 -o custom-columns=Name:.metadata.name,Phase:.status.phase
```

7. Create a single instance of a **metallb** resource:

```
cat << EOF | oc apply -f -
apiVersion: metallb.io/v1beta1
kind: MetalLB
metadata:
  name: metallb
  namespace: metallb-system
EOF
```

8. Verify that the deployment for the controller is running:

```
oc get deployment -n metallb-system controller
```

9. Verify that the daemon set for the speaker is running:

```
oc get daemonset -n metallb-system speaker
```

##### Cert-Manager Operator
1. Create the **cert-manager-operator** Operator namespace:

```
cat << EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
    name: cert-manager-operator
    labels:
      pod-security.kubernetes.io/enforce: privileged
      security.openshift.io/scc.podSecurityLabelSync: "false"
EOF
```

2. Create the **OperatorGroup**:

```
cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: cert-manager-operator
  namespace: cert-manager-operator
spec:
  targetNamespaces:
  - cert-manager-operator
  upgradeStrategy: Default
EOF
```
3. Confirm the OperatorGroup is installed in the namespace:

```
oc get operatorgroup -n cert-manager-operator
```

4. Subscribe to the **cert-manager** Operator:

```
cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  labels:
    operators.coreos.com/openshift-cert-manager-operator.cert-manager-operator: ""
  name: openshift-cert-manager-operator
  namespace: cert-manager-operator
spec:
  channel: stable-v1.12
  installPlanApproval: Automatic
  name: openshift-cert-manager-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: cert-manager-operator.v1.12.1
EOF
```
5. Confirm the **cert-manager** installplan is in the namespace:

```
oc get installplan -n cert-manager-operator
```

6. Confirm the **cert-manager** operator is installed:

```
oc get clusterserviceversion -n cert-manager-operator \
 -o custom-columns=Name:.metadata.name,Phase:.status.phase
```

7. Verify that cert-manager pods are up and running by entering the following command:

```
oc get pods -n cert-manager
```

#### Deploy a local Quay registry if needed

Log into the OCP console of your demo environment using the **admin** user
and provided password. Accept any SSL Certificate warnings.

##### Deploy the **Quay Operator**

1. Click on **Operators** to expand the section and then select "OperatorsHub".
2. Search for **Quay** and select **Red Hat Quay** and click **Install**
3. Use defaults and click **Install**

##### Prepare the registry:

1. On the **bastion host** create the **quay-enterprise** project:

```
oc new-project quay-enterprise
```

##### Create **Quay YAML and Secret**. Remember you will need to change uuid for the uuid of
your demo instance which is the variable between hypervisor and dynamic.opentlc.com in the
bastion_public_hostname.

```
cat << EOF >> config.yaml 
SERVER_HOSTNAME: quay.apps.uuid.dynamic.redhatworkshops.io
EOF
```

```
oc create secret generic --from-file config.yaml=./config.yaml config-bundle-secret
```

##### Create the **QuayRegistry YAML, apply and wait for it to be ready**

```
cat << EOF >> quayregistry.yaml
apiVersion: quay.redhat.com/v1
kind: QuayRegistry
metadata:
  name: openstack-internal-registry
  namespace: quay-enterprise
spec:
  configBundleSecret: config-bundle-secret
  components:
    - kind: clair
      managed: false
    - kind: horizontalpodautoscaler
      managed: false
    - kind: mirror
      managed: false
    - kind: monitoring
      managed: false
EOF
```

```
oc create -n quay-enterprise -f quayregistry.yaml
```

Wait until all pods are in running and ready state:

```
oc get pods -n quay-enterprise -w
```

Which should look similar to below when ready:

```
NAME                                                          READY   STATUS      RESTARTS   AGE
openstack-internal-registry-clair-postgres-84b7b8d94d-klpl5   1/1     Running     0          3m35s
openstack-internal-registry-quay-app-76f7784b4c-9ffzb         1/1     Running     0          3m5s
openstack-internal-registry-quay-app-76f7784b4c-xrl2l         1/1     Running     0          3m5s
openstack-internal-registry-quay-database-9654cf65d-mblkm     1/1     Running     0          3m35s
openstack-internal-registry-quay-redis-c8d944c9d-ng2xp        1/1     Running     0          3m36s
```

##### Create the quay_user and private registry

Navigate to quay.apps.uuid.dynamic.redhatworkshops.io and create the **quay_user** user
account with the password **openstack** and create a private repository called
**dp3-openstack-operator-index**.

##### Obtain the **self-signed certificate** for the **Quay Registry** and patch the cluster

```
ex +'/BEGIN CERTIFICATE/,/END CERTIFICATE/p' <(echo | openssl s_client -showcerts -connect quay.apps.uuid.dynamic.redhatworkshops.io:443) -scq > server.pem
```
```
oc create configmap registry-config --from-file=quay.apps.uuid.dynamic.redhatworkshops.io=server.pem -n openshift-config
```
```
oc patch image.config.openshift.io/cluster --patch '{"spec":{"additionalTrustedCA":{"name":"registry-config"}}}' --type=merge
```
```
oc patch image.config.openshift.io/cluster --type merge --patch '{"spec":{"registrySources":{"allowedRegistries":["docker-registry.upshift.redhat.com","registry.redhat.io","quay.io","registry-proxy.engineering.redhat.com","gcr.io","image-registry.openshift-image-registry.svc:5000","quay.apps.uuid.dynamic.redhatworkshops.io"],"insecureRegistries":["docker-registry.upshift.redhat.com","quay.apps.uuid.dynamic.redhatworkshops.io"]}}}'
```

Move the **certificates** to the correct location and update:

```
sudo cp server.pem /etc/pki/ca-trust/source/anchors/
```
```
sudo cp server.pem /etc/pki/tls/certs/
```
```
sudo update-ca-trust
```

[back](index.md) [next](install-operators.md)
