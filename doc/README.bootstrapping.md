# Bootstrapping

## NeCTAR

### Creating The Node

When creating the node, you'll need to first upload your SSH public key, so the
node can be configured with initial access.

When creating the node, if you can find an `emii_base_xx` image, you may use
it. The advantage of using this "preloaded" image is that the initial chef run
will pull in less dependencies. This image should exist on the Melbourne zones
of NeCTAR.

By all means, it is absolutely fine to use a vanilla Ubuntu 12.04 image if the
preloaded emii image does not exist.

Please place the node in the `melbourne-np` or `melbourne-qh2` zones when
bootstrapping a node in the Melbourne zone.

### Firewalling

You will have to allow at least SSH (port 22) in order to bootstrap the node.
The easiest way is to attach the `SSH` security group to the node.

### EBS (Elastic Block Storage) volume

On NeCTAR nodes, the /dev/vdb volume will have to be changed to be mounted on
`/mnt/ebs`.

This can be done with the following snippet:
```
# remove entry in /etc/fstab
sed -i -e '/\/dev\/vdb/d' /etc/fstab

# mount volume in ebs place
umount /mnt && mkdir /mnt/ebs && mount /dev/vdb /mnt/ebs
```

### Boostrapping With Chef

This should get you going:
```
NODE_NAME=1-nec-mel
NODE_IP_ADDRESS=115.146.10.10

knife solo prepare ubuntu@${NODE_IP_ADDRESS}
knife solo cook ubuntu@${NODE_IP_ADDRESS} -N ${NODE_NAME} nodes/${NODE_NAME}.emii.org.au.json
```

## NSP

NSP is for production only VMs with the exception of high performing test
instances (instances which need access to fast disk for instance).

### Creating The Node

When creating your node, you will first have to make sure your public SSH key is
recognized, so you have initial access after the VM is booted.

Generally speaking, the easiest way is to talk to dfruehauf.

### Firewalling

You will have to attach a public IP address to the newly created node and
create at least one rule allowing SSH on this public IP address.

### EBS (Elastic Block Storage) volume

On NSP machines, you'll need to create the EBS volume. see
[README.ebs.md](README.ebs.md) for fun with LVM and such.

### Bootstrapping With Chef

Once the preparations are over, you're ready to bootstrap the node.

Simply bootstrapping a node (6-nsp-mel in this case):
```
NODE_NAME=6-nsp-mel
NODE_IP_ADDRESS=103.10.10.10

knife solo prepare root@${NODE_IP_ADDRESS}
knife solo cook root@${NODE_IP_ADDRESS} -N ${NODE_NAME} nodes/${NODE_NAME}.emii.org.au.json
```
