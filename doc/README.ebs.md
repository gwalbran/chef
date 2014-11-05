EBS
===

One of the most annoying problems is having only 10GB of a root disk partition.
This is by all means too small. In order to overcome this we use an EBS mount,
which stands for "Elastic Block Storage", in other words - just more storage :)

EBS volume are managed with LVM, so they can grow (online) and shrink (ext4
doesn't support online shrinking).

Creation of a new EBS volume
============================
Creating an EBS is pretty straight forward, follow these steps:
 * Attach a 40GB volume to the machine (via NSP portal), usually called EBS-X-Y
   * X is usually the machine number, so 3 for `3-nsp-mel`
   * Y is the volume number, so start with 1 and go up
   * The third volume for a machine called 5-nsp-mel would be `EBS-5-3`
 * Login to machine and run:

```
#!/bin/bash

# set device
DEVICE=/dev/xvdb

# create LVM partition on all of disk
parted -s -a optimal $DEVICE mklabel msdos -- mkpart primary ext4 1 -1 set 1 lvm on

# create physical volume
pvcreate ${DEVICE}1

# create volume group ebs
vgcreate ebs ${DEVICE}1

# create logical volbume called 1 in ebs volume group
lvcreate -n 1 -l 100%VG ebs

# create filesystem on logical volume
mkfs.ext4 /dev/mapper/ebs-1
```

Extending an existing EBS volume
================================

 * Attach another 40GB volume as described above
 * Login to machine and run:

```
#!/bin/bash

# set device
DEVICE=/dev/xvdc

# create LVM partition on all of disk
parted -s -a optimal $DEVICE mklabel msdos -- mkpart primary ext4 1 -1 set 1 lvm on

# create physical volume
pvcreate ${DEVICE}1

# extend volume group
vgextend ebs ${DEVICE}1

# extend logical volume
lvextend -l 100%VG /dev/ebs/1

# grow filesystem
resize2fs /dev/mapper/ebs-1
```

