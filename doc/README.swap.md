Swap Space
==========

To create swap space on EBS, use the follwing commands (as root):
```
SWAP_LOCATION=/mnt/ebs/swap
SWAP_SIZE_MB=4096 # 4GB

dd if=/dev/zero of=$SWAP_LOCATION count=$SWAP_SIZE_MB bs=1M
mkswap $SWAP_LOCATION
swapon $SWAP_LOCATION
echo "$SWAP_LOCATION swap swap defaults 0 0" >> /etc/fstab
```
