# Preliminary steps
Deploy your environment in demo.redhat.com and get the UUID of your deployment ($your_deployment_UUID) in the e-mail instructions.

Connect to the hypervisor then connect to the bastion:

`ssh root@192.168.123.100`
Clone this repo and run the following script:

```
chmod +x replace_UUID.sh
./replace_UUID $your_deployment_UUID
```

You can visualize this README.md file in your console as the uuid will be replaced by your deploymend id.

# Prepare the disconnected registry
Navigate to the OCP console and install quay operator in the UI

From the baremetal host acccess to the bastion:

`ssh root@192.168.123.100`
```
oc new-project quay-enterprise
oc project quay-enterprise
```
Change UUID by your $your_deployment_UUID of your project

```
cat << EOF >> config.yaml
SERVER_HOSTNAME: quay.apps.uuid.dynamic.redhatworkshops.io
EOF
oc create secret generic --from-file config.yaml=./config.yaml config-bundle-secret
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
oc create -n quay-enterprise -f quayregistry.yaml
oc get pods -n quay-enterprise -w
```
Wait until all pods are in running and ready state:

```
NAME                                                          READY   STATUS      RESTARTS   AGE
openstack-internal-registry-clair-postgres-84b7b8d94d-klpl5   1/1     Running     0          3m35s
openstack-internal-registry-quay-app-76f7784b4c-9ffzb         1/1     Running     0          3m5s
openstack-internal-registry-quay-app-76f7784b4c-xrl2l         1/1     Running     0          3m5s
openstack-internal-registry-quay-database-9654cf65d-mblkm     1/1     Running     0          3m35s
openstack-internal-registry-quay-redis-c8d944c9d-ng2xp        1/1     Running     0          3m36s

```

Navigate to quay.apps.uuid.dynamic.redhatworkshops.io Create quay_user user account and password openstack. Create private repository dp2-openstack-operator-index
```
ex +'/BEGIN CERTIFICATE/,/END CERTIFICATE/p' <(echo | openssl s_client -showcerts -connect quay.apps.s69p4.dynamic.redhatworkshops.io:443) -scq > server.pem
oc create configmap registry-config \
 --from-file=quay.apps.s69p4.dynamic.redhatworkshops.io=server.pem \
 -n openshift-config
oc patch image.config.openshift.io/cluster --patch='{"spec":{"additionalTrustedCA":{"name":"registry-config"}}}' --type=merge
oc patch image.config.openshift.io/cluster --type merge --patch='{"spec":{"registrySources":{"allowedRegistries":["docker-registry.upshift.redhat.com","registry.redhat.io","quay.io","registry-proxy.engineering.redhat.com","gcr.io","image-registry.openshift-image-registry.svc:5000", "quay.apps.s69p4.dynamic.redhatworkshops.io"],"insecureRegistries":["docker-registry.upshift.redhat.com","quay.apps.s69p4.dynamic.redhatworkshops.io"]}}}'
```
```
sudo cp server.pem /etc/pki/ca-trust/source/anchors/
sudo cp server.pem /etc/pki/tls/certs/
sudo update-ca-trust
wget https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/opm-linux.tar.gz
tar -xvzf opm-linux.tar.gz
podman login registry.redhat.io
podman login --username "quay_user" --password "openstack" quay.apps.s69p4.dynamic.redhatworkshops.io/quay_user/dp2-openstack-operator-index
./opm index add -u podman --pull-tool podman --tag quay.apps.s69p4.dynamic.redhatworkshops.io/quay_user/dp2-openstack-operator-index:latest -b "registry.redhat.io/rhosp-dev-preview/openstack-operator-bundle:0.1.2,registry.redhat.io/rhosp-dev-preview/swift-operator-bundle:0.1.2,registry.redhat.io/rhosp-dev-preview/glance-operator-bundle:0.1.2,registry.redhat.io/rhosp-dev-preview/infra-operator-bundle:0.1.2,registry.redhat.io/rhosp-dev-preview/ironic-operator-bundle:0.1.2,registry.redhat.io/rhosp-dev-preview/keystone-operator-bundle:0.1.2,registry.redhat.io/rhosp-dev-preview/ovn-operator-bundle:0.1.2,registry.redhat.io/rhosp-dev-preview/placement-operator-bundle:0.1.2,registry.redhat.io/rhosp-dev-preview/telemetry-operator-bundle:0.1.2,registry.redhat.io/rhosp-dev-preview/heat-operator-bundle:0.1.2,registry.redhat.io/rhosp-dev-preview/cinder-operator-bundle:0.1.2,registry.redhat.io/rhosp-dev-preview/manila-operator-bundle:0.1.2,registry.redhat.io/rhosp-dev-preview/neutron-operator-bundle:0.1.2,registry.redhat.io/rhosp-dev-preview/nova-operator-bundle:0.1.2,registry.redhat.io/rhosp-dev-preview/ansibleee-operator-bundle:0.1.2,registry.redhat.io/rhosp-dev-preview/mariadb-operator-bundle:0.1.2,registry.redhat.io/rhosp-dev-preview/openstack-baremetal-operator-bundle:0.1.2,registry.redhat.io/rhosp-dev-preview/rabbitmq-cluster-operator-bundle:0.1.2,registry.redhat.io/rhosp-dev-preview/horizon-operator-bundle:0.1.2,registry.redhat.io/rhosp-dev-preview/octavia-operator-bundle:0.1.2" --mode semver 
podman push quay.apps.s69p4.dynamic.redhatworkshops.io/quay_user/dp2-openstack-operator-index:latest
```

# Prepare NFS storage
Access to the baremetal host

From the baremetal host acccess to the bastion:

`ssh root@192.168.123.100`

Create additional folders to host more PVs:

```
mkdir /nfs/pv6
mkdir /nfs/pv7
mkdir /nfs/pv8
mkdir /nfs/pv9
mkdir /nfs/pv10
mkdir /nfs/pv11
chmod 777 /nfs/pv*
```
Clone this repo. Create more persistent volumes:

`oc create -f nfs-storage.yaml`

# Install nmstate and metallb core prerequirements

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

cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  annotations:
    olm.providedAPIs: NMState.v1.nmstate.io
  generateName: openshift-nmstate-
  name: openshift-nmstate-tn6k8
  namespace: openshift-nmstate
spec:
  targetNamespaces:
  - openshift-nmstate
EOF

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

while ! (oc get pod --no-headers=true -l app=kubernetes-nmstate-operator -n openshift-nmstate| grep "nmstate-operator"); do sleep 10; done

cat << EOF | oc apply -f -
apiVersion: nmstate.io/v1
kind: NMState
metadata:
  name: nmstate
EOF

cat << EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
    name: metallb-system
    labels:
      pod-security.kubernetes.io/enforce: privileged
      security.openshift.io/scc.podSecurityLabelSync: "false"
EOF

cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: metallb-operator
  namespace: metallb-system
EOF

cat << EOF | oc apply -f -
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

while ! (oc get pod --no-headers=true -l control-plane=controller-manager -n metallb-system| grep "metallb-operator-controller"); do sleep 10; done
sleep 20

cat << EOF | oc apply -f -
apiVersion: metallb.io/v1beta1
kind: MetalLB
metadata:
  name: metallb
  namespace: metallb-system
EOF
```
# Create the needed namespaces
```
oc new-project openstack-operators
oc new-project openstack
```

# Configure the master/worker nodes using nccp
```
oc apply -f osp-ng-nncp-w1.yaml
oc apply -f osp-ng-nncp-w2.yaml
oc apply -f osp-ng-nncp-w3.yaml
oc apply -f osp-ng-nncp-m1.yaml
oc apply -f osp-ng-nncp-m2.yaml
oc apply -f osp-ng-nncp-m3.yaml
oc get nncp -w
```

# Create network attachment definitions
```
oc apply -f osp-ng-netattach.yaml
```

# Create metallb address pools and L2 advertisements
```
oc apply -f osp-ng-metal-lb-ip-address-pools.yaml
oc apply -f osp-ng-metal-lb-l2-avertisements.yaml
```


# Install OSP DP2 operators
```
cd
podman login registry.redhat.io --authfile /root/auth.json
podman login --username "quay_user" --password "openstack" quay.apps.uuid.dynamic.redhatworkshops.io/quay_user/dp2-openstack-operator-index --authfile /root/auth.json
oc create secret generic osp-operators-secret \
    -n openstack-operators \
    --from-file=.dockerconfigjson=/root/auth.json \
    --type=kubernetes.io/dockerconfigjson

Edit osp-ng-openstack-operator.yaml and replace the UUID with the right one of your environment:

vi osp-ng-openstack-operator.yaml
oc apply -f osp-ng-openstack-operator.yaml
```

# Create the openstack secret
`oc create -f osp-ng-ctlplane-secret.yaml`

# Create the openstack control plane
`oc create -f osp-ng-ctlplne-deploy.yaml`

# Create dataplane network
```
oc apply -f osp-ng-dataplane-netconfig.yaml
```

# Prepare RHEL 9.2 hosts for compute hosts
In the hypervisor/baremetal host:

Copy link address from RHEL KVM 9.2 Guest image qcow2 from https://access.redhat.com/downloads/content/479/ver=/rhel---9/9.2/x86_64/product-software

```
sudo -i
cd /var/lib/libvirt/images
curl -o rhel9-2.qcow2 "https://access.cdn.redhat.com/content/origin/files/sha256/34/34ff41b5274692c984e3860b21136af8b6ae502744c6c7578dda82002fba0287/rhel-9.2-x86_64-kvm.qcow2?token"
cp rhel9-2.qcow2 rhel9-guest.qcow2
qemu-img info rhel9-guest.qcow2
qemu-img resize rhel9-guest.qcow2 +90G
chown -R qemu:qemu rhel9-*.qcow2
virt-customize -a rhel9-guest.qcow2 --run-command 'growpart /dev/sda 4'
virt-customize -a rhel9-guest.qcow2 --run-command 'xfs_growfs /'
virt-customize -a rhel9-guest.qcow2 --root-password password:redhat
virt-customize -a rhel9-guest.qcow2 --run-command 'systemctl disable cloud-init'
virt-customize -a /var/lib/libvirt/images/rhel9-guest.qcow2 --ssh-inject root:file:/root/.ssh/id_rsa.pub
virt-customize -a /var/lib/libvirt/images/rhel9-guest.qcow2 --selinux-relabel
qemu-img create -f qcow2 -F qcow2 -b /var/lib/libvirt/images/rhel9-guest.qcow2 /var/lib/libvirt/images/osp-compute-0.qcow2
virt-install --virt-type kvm --ram 16384 --vcpus 4 --cpu=host-passthrough --os-variant rhel8.4 --disk path=/var/lib/libvirt/images/osp-compute-0.qcow2,device=disk,bus=virtio,format=qcow2 --network network:ocp4-provisioning --network network:ocp4-net --boot hd,network --noautoconsole --vnc --name osp-compute0 --noreboot
virsh start osp-compute0
```
Watch until you have an IP from the 192.168.123.0/24:

```
watch virsh domifaddr osp-compute0 --source agent
(control + C to continue)
virsh domifaddr osp-compute0 --source agent
```

ssh to the node via network:ocp4-net:

```
ssh root@192.168.123.61
ex +'/BEGIN CERTIFICATE/,/END CERTIFICATE/p' <(echo | openssl s_client -showcerts -connect quay.apps.uuid.dynamic.redhatworkshops.io:443) -scq > server.pem
sudo cp server.pem /etc/pki/ca-trust/source/anchors/
sudo cp server.pem /etc/pki/tls/certs/
sudo update-ca-trust
nmcli co delete 'Wired connection 1'
nmcli con add con-name "static-eth0" ifname eth0 type ethernet ip4 172.22.0.100/24 ipv4.dns "172.22.0.89"
nmcli con up "static-eth0"
nmcli co delete 'Wired connection 2'
nmcli con add con-name "static-eth1" ifname eth1 type ethernet ip4 192.168.123.61/24 ipv4.dns "192.168.123.100" ipv4.gateway "192.168.123.1"
nmcli con up "static-eth1"
cat >> /etc/resolv.conf <<EOF
# Generated by NetworkManager
search aio.example.com
nameserver 172.22.0.89
EOF
logout
```

log back to the compute:

```
ssh root@172.22.0.100
sudo hostnamectl set-hostname edpm-compute-0.aio.example.com
subscription-manager register
sudo subscription-manager repos --disable=*
subscription-manager repos --enable=rhel-9-for-x86_64-baseos-rpms --enable=rhel-9-for-x86_64-appstream-rpms --enable=rhel-9-for-x86_64-highavailability-rpms --enable=openstack-17.1-for-rhel-9-x86_64-rpms --enable=fast-datapath-for-rhel-9-x86_64-rpms
sudo subscription-manager release --set=9.2
sudo dnf install -y podman
podman login --username "quay_user" --password "openstack" quay.apps.uuid.dynamic.redhatworkshops.io/quay_user/dp2-openstack-operator-index
podman login registry.redhat.io
logout
```

snapshot the compute

`virsh snapshot-create-as osp-compute0 preprovisioned`


# Prepare the ansible ssh key to connect to the compute nodes:

In the hypervisor:
```
scp /root/.ssh/id_rsa root@192.168.123.100:/root/.ssh/id_rsa_compute
scp /root/.ssh/id_rsa.pub root@192.168.123.100:/root/.ssh/id_rsa_compute.pub
```

In the bastion:

```
oc create secret generic dataplane-ansible-ssh-private-key-secret \
--save-config \
--dry-run=client \
--from-file=authorized_keys=/root/.ssh/id_rsa_compute.pub \
--from-file=ssh-privatekey=/root/.ssh/id_rsa_compute \
--from-file=ssh-publickey=/root/.ssh/id_rsa_compute.pub \
-n openstack \
-o yaml | oc apply -f-
```

# Create the dataplane EDPM deployment

Edit the osp-ng-dataplne-node-set-deploy.yaml and modify the registry login information
```
vi osp-ng-dataplne-node-set-deploy.yaml
[...]
         edpm_container_registry_logins:
          quay.apps.uuid.dynamic.redhatworkshops.io:
            quay_user: openstack
          registry.redhat.io:
            testuser: testpassword

```
Then apply it:
```
oc apply -f osp-ng-dataplne-node-set-deploy.yaml
```

Apply the Node set deployment

```
oc apply -f osp-ng-dataplne-deployment.yaml
```

# accessing the openstackclient pod

```
oc rsh -n openstack openstackclient
cd /home/cloud-admin
openstack compute service list
openstack network agent list
```