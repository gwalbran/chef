#!/bin/bash

# remove wms and wfs scanners
# TODO remove once ran on all POs VMs
remove_scanners() {
    local webapps_path="/var/lib/tomcat7/default/webapps"
    local -i scanners_count=`vagrant ssh po -- "ls -1 /var/lib/tomcat7/default/webapps/*scanner* 2> /dev/null" | grep -v ^WARNING: | wc -l`
    if [ $scanners_count -gt 0 ]; then
        echo "Removing scanners and restarting tomcat"
        vagrant ssh po -- "rm -rf $webapps_path/*scanner* && sudo /etc/init.d/tomcat7_default restart"
    fi
}

export VAGRANT_STATIC_IP=10.11.12.13
export VAGRANT_MEMORY=3072

declare -r GEOSERVER_GIT_REPO=git@github.com:aodn/geoserver-config
declare -r PO_VM_NAME=po

if [ ! -d "shared_src/geoserver/.git" ]; then
    mkdir -p shared_src
    (cd shared_src && git clone $GEOSERVER_GIT_REPO geoserver)
fi

declare -r RESTORE_USER='data_bags/users/restore.json'
if [ ! -f "$RESTORE_USER" ]; then
    echo "Please get a restore key from the dev team and place it in '$RESTORE_USER'"
    exit 1
fi

declare -r HARVEST_READ_PO='data_bags/jndi_resources/harvest-read-po.json'
harvest_read_po_password=`grep 'password' $HARVEST_READ_PO | cut -d: -f2 | cut -d\" -f2`
if [[ "$harvest_read_po_password" = "geoserver_po" ]]; then
    echo "Please edit '$HARVEST_READ_PO' and plant a password"
    exit 1
fi

if vagrant status $PO_VM_NAME | grep "^$PO_VM_NAME" | grep -q "\brunning\b"; then
    # overcome https://github.com/mitchellh/vagrant/issues/5199
    rm -f .vagrant/machines/$PO_VM_NAME/virtualbox/synced_folders
    vagrant reload $PO_VM_NAME --provision
else
    # run with --provision to run provisioning if machine was halted
    vagrant up po --provision
fi

remove_scanners
