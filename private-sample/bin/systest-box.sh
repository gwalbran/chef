#!/bin/bash

SYSTEST_VM_NAME=systest

restore_geonetwork() {
    vagrant ssh $SYSTEST_VM_NAME -- "sudo /mnt/ebs/backups/restore/restore.sh" && \
    vagrant ssh $SYSTEST_VM_NAME -- "sudo /etc/init.d/tomcat7_geonetwork_123 restart"
}

declare -r RESTORE_USER='data_bags/users/restore.json'
if [ ! -f "$RESTORE_USER" ]; then
    echo "Please get a restore key from the dev team and place it in '$RESTORE_USER'"
    exit 1
fi

declare -r HARVEST_SYSTEST='data_bags/jndi_resources/harvest-systest.json'
harvest_systest_password=`grep 'password' $HARVEST_SYSTEST | cut -d: -f2 | cut -d\" -f2`
if [[ "$harvest_systest_password" = "geoserver_systest" ]]; then
    echo "Please edit '$HARVEST_SYSTEST' and plant a password"
    exit 1
fi

if vagrant status $SYSTEST_VM_NAME | grep "^$SYSTEST_VM_NAME" | grep -q "\brunning\b"; then
    # overcome https://github.com/mitchellh/vagrant/issues/5199
    rm -f .vagrant/machines/$SYSTEST_VM_NAME/virtualbox/synced_folders
    vagrant reload $SYSTEST_VM_NAME --provision && restore_geonetwork
else
    # run with --provision to run provisioning if machine was halted
    vagrant up $SYSTEST_VM_NAME --provision && restore_geonetwork
fi

