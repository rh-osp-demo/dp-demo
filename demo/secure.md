# Configuration, Installation, and Using Red Hat OpenStack Services on OpenShift(RHOSO)

## Preparing Red Hat OpenShift Container Platform for Red Hat OpenStack Platform

### Providing secure access to the Red Hat OpenStack Platform services

1. Run the following command twice to create a <base64_password> and <base64_password_heat>
for use in next step:

echo -n <password> | base64

2. Create a **Secret CR** file on your workstation **openstack-service-secret.yaml**

apiVersion: v1
data:
  AdminPassword: <base64_password>
  CeilometerPassword: <base64_password>
  CinderDatabasePassword: <base64_password>
  CinderPassword: <base64_password>
  DatabasePassword: <base64_password>
  DbRootPassword: <base64_password>
  DesignateDatabasePassword: <base64_password>
  DesignatePassword: <base64_password>
  GlanceDatabasePassword: <base64_password>
  GlancePassword: <base64_password>
  HeatAuthEncryptionKey: <base64_password_heat>
  HeatDatabasePassword: <base64_password>
  HeatPassword: <base64_password>
  IronicDatabasePassword: <base64_password>
  IronicInspectorDatabasePassword: <base64_password>
  IronicInspectorPassword: <base64_password>
  IronicPassword: <base64_password>
  KeystoneDatabasePassword: <base64_password>
  ManilaDatabasePassword: <base64_password>
  ManilaPassword: <base64_password>
  MetadataSecret: <base64_password>
  NeutronDatabasePassword: <base64_password>
  NeutronPassword: <base64_password>
  NovaAPIDatabasePassword: <base64_password>
  NovaAPIMessageBusPassword: <base64_password>
  NovaCell0DatabasePassword: <base64_password>
  NovaCell0MessageBusPassword: <base64_password>
  NovaCell1DatabasePassword: <base64_password>
  NovaCell1MessageBusPassword: <base64_password>
  NovaPassword: <base64_password>
  OctaviaDatabasePassword: <base64_password>
  OctaviaPassword: <base64_password>
  PlacementDatabasePassword: <base64_password>
  PlacementPassword: <base64_password>
  SwiftPassword: <base64_password>
kind: Secret
metadata:
  name: osp-secret
  namespace: openstack
type: Opaque

3. Create the **Secret** in the cluster:

`oc create -f openstack-service-secret.yaml`

4. Verify the **Secret** was created:

`oc describe secret osp-secret -n openstack`


[back](install-operators.md) [next](network-isolation.md)
