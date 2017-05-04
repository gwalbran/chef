#!/bin/bash

if [ -z "$AWS_ACCESS_KEY" -o -z "$AWS_SECRET_KEY" -o -z "$SSH_KEY" ]; then
  echo "AWS_ACCESS_KEY, AWS_SECRET_KEY and SSH_KEY environment variables must be set"
  exit 1
fi
REGION=ap-southeast-2
INSTANCE_TYPE=t2.small
SOURCE_AMI=ami-4e686b2d
AMI_NAME=xenial-server-amd64
VERSION=0.2
CHEF_VERSION=12.4.3

PACKER_TEMPLATE=basebox-aws-xenial.json

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
cd private/packer
packer build \
    -var "access_key=$AWS_ACCESS_KEY" \
    -var "secret_key=$AWS_SECRET_KEY" \
    -var "region=$REGION" \
    -var "instance_type=$INSTANCE_TYPE" \
    -var "source_ami=$SOURCE_AMI" \
    -var "ami_name=$AMI_NAME" \
    -var "version=$VERSION" \
    -var "ssh_key=$SSH_KEY" \
    -var "chef_version=$CHEF_VERSION" \
    $PACKER_TEMPLATE

