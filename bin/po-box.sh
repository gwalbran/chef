#!/bin/bash

export VAGRANT_STATIC_IP=10.11.12.13
export VAGRANT_MEMORY=3072

declare -r GEOSERVER_GIT_REPO=git@github.com:aodn/geoserver-config
declare -r DATA_SERVICES_GIT_REPO=git@github.com:aodn/data-services
declare -r PO_VM_NAME=po

if [ ! -d "src/geoserver/.git" ]; then
    mkdir -p src
    if [ -d "shared_src/geoserver/.git" ]; then
        mv shared_src/geoserver src/geoserver
        echo "NOTICE!!!!"
        echo "NOTICE!!!!"
        echo "NOTICE!!!!"
        echo "Your geoserver repository was moved from 'shared_src/geoserver' to 'src/geoserver'"
    else
        (cd src && git clone $GEOSERVER_GIT_REPO geoserver)
    fi
fi

if [ ! -d "src/data-services/.git" ]; then
    mkdir -p src
    (cd src && git clone $DATA_SERVICES_GIT_REPO data-services)
fi

declare -r RESTORE_USER='data_bags/users/restore.json'
declare -r SSHFS_USER='data_bags/users/sshfs.json'
if [ ! -f "$RESTORE_USER" ]; then
    if test -d ../chef-private; then
        echo "Probed chef-private directory at ../chef-private"
        mkdir -p `dirname $RESTORE_USER`
        cp -a ../chef-private/data_bags/users/restore.json $RESTORE_USER
        cp -a ../chef-private/data_bags/users/sshfs.json   $SSHFS_USER
    else
        echo "Please get a restore key from the dev team and place it in '$RESTORE_USER'"
        exit 1
    fi
fi

declare -r HARVEST_READ_PO='data_bags/jndi_resources/harvest-read-po.json'
harvest_read_po_password=`grep 'password' $HARVEST_READ_PO | cut -d: -f2 | cut -d\" -f2`

declare -r HARVEST_READ_PO_RC='data_bags/jndi_resources/harvest-read-po-rc.json'
harvest_read_po_rc_password=`grep 'password' $HARVEST_READ_PO_RC | cut -d: -f2 | cut -d\" -f2`

if [[ "$harvest_read_po_password" = "geoserver_po" || "$harvest_read_po_rc_password" = "geoserver_po" ]]; then
    echo "Please edit '$HARVEST_READ_PO' and '$HARVEST_READ_PO_RC' and plant valid passwords"
    exit 1
fi

if vagrant status $PO_VM_NAME | grep "^$PO_VM_NAME" | grep -q "\brunning\b"; then
    # overcome https://github.com/mitchellh/vagrant/issues/5199
    rm -f .vagrant/machines/$PO_VM_NAME/virtualbox/synced_folders
    vagrant reload $PO_VM_NAME --provision
else
    # run with --provision to run provisioning if machine was halted
    vagrant up $PO_VM_NAME --provision
fi