# Configuration, Installation, and Using Red Hat OpenStack Services on OpenShift

## Prerequisites for installation

Some prerequisites needed to install Red Hat OpenStack Services on OpenShift(RHOSO) are
already included in the demonstration environment such as:

- An operational OpenShift cluster running 4.13 which supports Multus CNI
- oc command line tool on your workstation(bastion host) 
- podman command line tool on your workstation(bastion host) 
- Access to repositories which contain the Dev Preview code
- Access to an existing registry or create a local Quay registry

###Deploy a local Quay registry if needed

Log into the OCP console of your demo environment using the **admin** user
and provided password. Accept any SSL Certificate warnings.

#### Deploy the **Local Storage**

1. Click on **Operators** to expand the section and then select "OperatorsHub".
2. Search for **Local** and select **Local Storage** and click **Install**
3. Use defaults and click **Install**
4. When installed from **Details** click on **Create Instance** under **Local Volume Set**
5. Give the **LocalVolumeSet** a name and use the defaults

#### Deploy **OpenShift Data Foundation Operator**

1. Click on **Operators** to expand the section and then select "OperatorsHub".
2. Search for **Data** and select **OpenShift Data Foundation** and click **Install**
3. Use defaults and click **Install**
4, Click **Refresh web console** when prompted
5. Once installed under **Details** click **Create StorageSystem**
6. Select **MultiCloud Object Gateway** as the Deployment type
7. Use the dropdown for an existing **StorageClass** to choose the **Local Storage** you
   created and click **Next**
8. Use the existing Security settings and click **Next**
9. Click on **Create StorageSystem** 

#### Create an **ObjectBucketClaim for NooBaa**

1. Expand **Storage** and select **Object Bucket Claim**
2. Click on **Create ObjectBucketClaim**
3. Click on **Edit YAML** and place the following in the Yaml
view and click **Create** when done

apiVersion: objectbucket.io/v1alpha1
kind: ObjectBucketClaim
metadata:
  name: noobaatest
  namespace: openshift-storage
spec:
  storageClassName: openshift-storage.noobaa.io
  generateBucketName: noobaatest


#### Deploy the **Quay Operator**

1. Click on **Operators** to expand the section and then select "OperatorsHub". 
2. Search for **Quay** and select **Red Hat Quay** and click **Install**
3. Use defaults and click **Install**

#### Create a Quay Registry
1. Click on **Create instance** and then change the name to **openstack**
2. Select **default-token** as the Config Bundle Secret
Note: You will need an Red Hat account.

[back](index.md) [next](install-operators.md)
