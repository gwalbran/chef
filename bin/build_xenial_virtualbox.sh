#!/bin/bash

VERSION=0.4
CHEF_VERSION=12.4.3
BOX_FILENAME=xenial-server-amd64
PACKER_TEMPLATE=basebox-virtualbox-xenial.json
DISK_SIZE=100000
ISO_URL=http://releases.ubuntu.com/16.04/ubuntu-16.04.2-server-amd64.iso
ISO_MD5_CHECKSUM=2bce60d18248df9980612619ff0b34e6

BASE_DIR=$(dirname $0)
cd $BASE_DIR/..

rm -f private; ln -s private-sample private
# Cleanup from previous builds
rm -rf private/packer/cookbooks*
rm -rf private/packer/output-*
rm -f  private/packer/*.box
# Get all vendor cookbooks via berkshelf
berks vendor private/packer/cookbooks1
# Get our cookbooks
cp -a cookbooks private/packer/cookbooks2
pushd private/packer
packer build \
    -var "chef_version=$CHEF_VERSION" \
    -var "disk_size=$DISK_SIZE" \
    -var "iso_url=$ISO_URL" \
    -var "iso_checksum=$ISO_MD5_CHECKSUM" \
    $PACKER_TEMPLATE
declare -i retval=$?
popd
BOX_FILENAME=${BOX_FILENAME}-chef-${CHEF_VERSION}-${VERSION}.box
mv private/packer/packer_virtualbox-iso_virtualbox.box $BOX_FILENAME
exit $retval

