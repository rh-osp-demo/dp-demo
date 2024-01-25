# Access the OpenStack

1. From the **bastion server** access the Control Plane

```
oc rsh -n openstack openstackclient
```

On Control Plane verify OpenStack:
```
cd /home/cloud-admin
openstack compute service list
openstack network agent list
logout
```

2. Create a VM

```
oc rsh -n openstack openstackclient
export GATEWAY=192.168.123.1
export PUBLIC_NETWORK_CIDR=192.168.123.1/24
export PRIVATE_NETWORK_CIDR=192.168.100.0/24
export PUBLIC_NET_START=192.168.123.91
export PUBLIC_NET_END=192.168.123.99
export DNS_SERVER=8.8.8.8
openstack flavor create --ram 512 --disk 1 --vcpu 1 --public tiny
curl -O -L https://github.com/cirros-dev/cirros/releases/download/0.6.2/cirros-0.6.2-x86_64-disk.img
openstack image create cirros --container-format bare --disk-format qcow2 --public --file cirros-0.6.2-x86_64-disk.img

ssh-keygen -m PEM -t rsa -b 2048 -f ~/.ssh/id_rsa_pem
openstack keypair create --public-key ~/.ssh/id_rsa_pem.pub default
openstack security group create basic
openstack security group rule create basic --protocol tcp --dst-port 22:22 --remote-ip 0.0.0.0/0
openstack security group rule create --protocol icmp basic
openstack security group rule create --protocol udp --dst-port 53:53 basic
openstack network create --external --provider-physical-network datacentre --provider-network-type flat public
openstack network create --internal private
openstack subnet create public-net \
--subnet-range $PUBLIC_NETWORK_CIDR \
--no-dhcp \
--gateway $GATEWAY \
--allocation-pool start=$PUBLIC_NET_START,end=$PUBLIC_NET_END \
--network public
openstack subnet create private-net \
--subnet-range $PRIVATE_NETWORK_CIDR \
--network private
openstack router create vrouter
openstack router set vrouter --external-gateway public
openstack router add subnet vrouter private-net

openstack server create \
    --flavor tiny --key-name default --network private --security-group basic \
    --image cirros test-server
openstack floating ip create public
openstack server add floating ip test-server <FLOATING_IP>
```
3. From the bastion access to the VM:

```
ssh cirros@<FLOATING_IP> (password is gocubsgo)
```

[back](create-dp.md) [start](index.md)
