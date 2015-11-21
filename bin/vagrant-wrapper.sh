#!/bin/bash

####################
# COMMON FUNCTIONS #
####################

# run on private-sample by default
rm -f private; ln -s private-sample private

# run action on vm
# $1 - vm name
# $2 - action
# "$@" - extra arguments
_run_vm() {
    local vm_name=$1; shift
    local action=$1; shift

    case "$action" in
        halt)
            vagrant halt $vm_name
            return 1 # prevent further commands from running after a halt
        ;;
        ssh)
            vagrant ssh $vm_name "$@"
        ;;
        *)
            if vagrant status $vm_name | grep "^$vm_name" | grep -q "\brunning\b"; then
                # overcome https://github.com/mitchellh/vagrant/issues/5199
                rm -f .vagrant/machines/$vm_name/virtualbox/synced_folders
                vagrant reload $vm_name --provision
            else
                # run with --provision to run provisioning if machine was halted
                vagrant up $vm_name --provision
            fi
        ;;
    esac
}

# clone a git repo (if not cloned yet)
# $1 - source
# $2 - destination
_clone_git_repo() {
    local src=$1; shift
    local dst=$1; shift
    if [ ! -d "$dst/.git" ]; then
        git clone $src $dst
    fi
}

# handle db credentials
# $1 - data bag to mock
_mock_data_bag() {
    local data_bag=$1; shift
    local mocked_data_bag=`echo $data_bag | sed -e 's/\.json/-mock\.json/'`

    if test -f $data_bag && ! cmp $data_bag $mocked_data_bag >& /dev/null; then
        # $data_bag exists and differs from $mocked_data_bag
        true
    else
        sed -e 's/-mock\"/"/' $mocked_data_bag > $data_bag
        echo "Please edit '$data_bag' and plant a valid password"
        return 1
    fi
}

# handle a private key
# $1 - key location
_handle_private_key() {
    local key_path=$1; shift

    if [ -f "$key_path" ]; then
        # good to go, key exists
        true
    elif [ -d ../chef-private ]; then
        echo "Probed chef-private directory at ../chef-private, taking '$key_path' from it"
        mkdir -p `dirname $key_path`
        cp -a ../chef-private/$key_path $key_path
        return $?
    else
        echo "Please get "`basename $key_path`" from the dev team and place it in '$key_path'"
        return 1
    fi
}


########################
# SYSTEST BOX SPECIFIC #
########################

declare -r SYSTEST_VM_NAME=systest

# main function for systest box
# "$@" - arguments
systest_box_main() {
    _handle_private_key data_bags/passwords/s3_imos_restore.json || return 1
    _mock_data_bag private-sample/data_bags/jndi_resources/harvest-systest.json || return 1

    _run_vm $SYSTEST_VM_NAME "$@" || return 1

    vagrant ssh $SYSTEST_VM_NAME -- "sudo /mnt/ebs/backups/restore/restore.sh" || return 1
    vagrant ssh $SYSTEST_VM_NAME -- "sudo /etc/init.d/tomcat7_geonetwork_123 restart" || return 1
}

###################
# PO BOX SPECIFIC #
###################

declare -r PO_VM_NAME=po

# main function for po box
# "$@" - arguments
po_box_main() {
    declare -r GEOSERVER_GIT_REPO=git@github.com:aodn/geoserver-config
    declare -r DATA_SERVICES_GIT_REPO=git@github.com:aodn/data-services

    export VAGRANT_STATIC_IP=10.11.12.13
    export VAGRANT_MEMORY=3072

    _clone_git_repo $GEOSERVER_GIT_REPO src/geoserver || return 1
    _clone_git_repo $DATA_SERVICES_GIT_REPO src/data-services || return 1

    local -i retval=0
    _handle_private_key data_bags/passwords/s3_imos_restore.json; let retval=$retval+$?
    _handle_private_key data_bags/users/sshfs.json > /dev/null

    _mock_data_bag private-sample/data_bags/jndi_resources/harvest-read-po.json; let retval=$retval+$?
    _mock_data_bag private-sample/data_bags/jndi_resources/harvest-read-po-rc.json; let retval=$retval+$?

    if [ $retval -ne 0 ]; then
        echo "Error(s) detected, not proceeding"
        return 1
    fi

    _run_vm $PO_VM_NAME "$@" || return 1
}

# main function for running talend
talend_main() {
    declare -r TALEND_CUSTOM_COMPONENTS="src/talend-components"
    declare -r TALEND_WORKSPACE="src/talend-workspace"
    declare -r TALEND_COMPONENTS_DOWNLOAD_URL="https://ci.aodn.org.au/job/talend_components_edge/lastSuccessfulBuild/artifact/directory-build/target/components-1.0.0-SNAPSHOT.zip"
    declare -r HARVESTERS_GIT_REPO="git@github.com:aodn/harvesters.git"

    _clone_git_repo $HARVESTERS_GIT_REPO src/harvesters || return 1
    _download_talend_components

    _run_vm $PO_VM_NAME ssh -- -X "cd /var/lib/talend && ./TOS_DI-linux-gtk-x86_64"
}

# download talend components (only if required)
_download_talend_components() {
    if [ ! -d "$TALEND_CUSTOM_COMPONENTS" ]; then
        mkdir -p $TALEND_CUSTOM_COMPONENTS
        curl -o $TALEND_CUSTOM_COMPONENTS/components.zip "$TALEND_COMPONENTS_DOWNLOAD_URL"
        (cd $TALEND_CUSTOM_COMPONENTS && unzip components.zip && rm components.zip)
    else
        echo "---------------------------------------------------------------"
        echo "Talend components already exists in '$TALEND_CUSTOM_COMPONENTS'"
        echo "If you wish to download a new version of talend-components, delete '$TALEND_CUSTOM_COMPONENTS'"
        echo "---------------------------------------------------------------"
    fi

    echo "#################################################################"
    echo "talend-components will be at '/vagrant/$TALEND_CUSTOM_COMPONENTS'"
    echo "#################################################################"
}

########
# MAIN #
########

main() {
    # po-box.sh -> po_box_main
    local main_function=`basename $0 | sed -e 's/\.sh//' -e 's/-/_/g'`"_main"
    $main_function "$@"
}

main "$@"
