# Configuration, Installation, and Using Red Hat OpenStack Services on OpenShift

## Prerequisites for installation

Some prerequisites needed to install Red Hat OpenStack Services on OpenShift(RHOSO) are
already included in the demonstration environment such as:

- An operational OpenShift cluster running 4.13 which supports Multus CNI
- oc command line tool on your workstation(bastion host) 
- podman command line tool on your workstation(bastion host) 
- Access to repositories which contain the Dev Preview code
- Access to an existing registry(local or in your environment)

## Create a **QuayRegistry** in your provided Red Hat Quay

1. Navigate to your **Red Hat Quay** in **Installed Operators** and in
the **openshift-operators** Namespace
2. Click on **Create instance** and then change the name to **openstack**
3. Select **default-token** as the Config Bundle Secret
4, Click **Create**
Note: You will need an Red Hat account.

[back](index.md) [next](install-operators.md)
