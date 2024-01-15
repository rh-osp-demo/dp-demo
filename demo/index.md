Welcome to the Red Hat OpenStack Services on OpenShift(RHOSO) demonstration instructions. These instructions will
guide you through the installation of the next generation of Red Hat's OpenStack product onto an existing
OpenShift Cluster utilizing a bastion host and a single host for the data plane.

In this demonstration, you will use the following infrastructure on RHEL 9.2:
3 node 4.14 OCP cluster
bastion host
dataplane

In this demonstration, you will cover the following topics:

- [*Perform Pre-requisites*](prereqs.md)
- [*Install the Red Hat OpenStack Platform service Operators*](install-operators.md)
- [*Configure secure access for OpenStack services*](secure.md)
- [*Prepare OCP for OpenStack network isolation*](network-isolation.md)
- [*Create the control plane*](create-cp.md)
- [*Create the data plane*](create-dp.md)
- [*Access the data plane*](access.md)

Within the demo environment, you will be able to copy and paste the specified commands into the CLI. For some steps you may also need to edit some of the commands from the 
instructions. **Be sure to review all commands carefully both for functionality and syntax!**

When you're ready, click "next" to get started ...

[next](prereqs.md)
