#!/bin/bash

# Written by Dan Fruehauf <dan.fruehauf@utas.edu.au>

# script to provision nodes via vagrant and check their status

# by default use virtualbox
declare -r VAGRANT_DEFAULT_PROVIDER=virtualbox

# vagrant key for provisioning
declare -r VAGRANT_SSH_KEY=vagrant/ssh/id_rsa

# use prepare-box.sh to prepare a machine
declare -r PREPARE_BOX=prepare-box.sh

# lock directory to use
declare -r VAGRANT_LOCK=$HOME/vagrant-lock

# locks, to prevent multiple access while creating the VM
_lock() {
    echo -n "Obtaining vagrant lock..."
    local -i i=0
    while [ $i -lt 300 ]; do
        mkdir $VAGRANT_LOCK >& /dev/null && \
            trap "{ rmdir $VAGRANT_LOCK; echo 'Critical: Aborted.'; exit 2; }" INT && \
            echo "Done!" && \
            return 0
        echo -n "."
        sleep 1
        let i=$i+1
    done
    echo "Critical: Couldn't obtain exclusive vagrant lock '$VAGRANT_LOCK'"
    exit 2
}

# unlocks
_unlock() {
    rmdir $VAGRANT_LOCK
}

# create a VM (i.e. vagrant up)
# $1 - node_name
# $2 - provider
# $3 - retry_max
create_node() {
    local node_name=$1; shift
    local provider=$1; shift
    local retry_max=$1; shift

    local -i retry_count=0
    while [  $retry_count -lt $retry_max ]; do
        let retry_count=$retry_count+1

        echo `date`" Creating '$node_name', attempt: $retry_count/$retry_max..."
        if [ `uname` == "Darwin" ]; then
            vagrant up $node_name --no-provision --provider=$provider  # No timeout on OS X :-(
        else
            timeout 2h vagrant up $node_name --no-provision --provider=$provider
        fi
    done
}

# export a node
# $1 - provider
# $2 - node name
# $3 - cleanup (delete users, etc), 1 to cleanup, 0 to not
export_node() {
    local provider=$1; shift
    local node_name=$1; shift
	local -i cleanup=$1; shift

    echo `date`" Exporting '$node_name'"
    if [ $cleanup -eq 1 ]; then
    	echo `date`" Performing cleanup on '$node_name'"
        machine_cleanup $node_name
    fi

    # pre_export should also power off the machine
    ${provider}_pre_export $node_name && \
        ${provider}_export $node_name && \
        ${provider}_post_export $node_name
}

# provision a node
# $1 - provider
# $2 - node name
# $3 - clear
# $4 - export
# $5 - retry_max
# $6 - cleanup (1 or 0)
provision_node() {
    local provider=$1; shift
    local provisioner=$1; shift
    local node_name=$1; shift
    local clear=$1; shift
    local export=$1; shift
    local retry_max=$1; shift
    local -i cleanup=$1; shift

    # export VAGRANT_NODE=nodes/${node_name}.json
    # ! test -f $VAGRANT_NODE && echo "Node '$VAGRANT_NODE' does not exist in configuration, check nodes/*" && exit 3

    local -i retval=0

    _lock

    # sleep after locking, perhaps avoiding some more race conditions
    sleep 15

    create_node $node_name $provider $retry_max

    _unlock
    retval=$?

    if [ $retval -eq 0 ]; then

        echo `date`" Provisioning '$node_name'..."
        ${provisioner}_provision $node_name
        retval=$?

        if [ $retval -eq 0 ]; then
            if [ "$export" = "yes" ]; then
                export_node $provider $node_name $cleanup
            fi
            if [ "$clear" = "yes" ]; then
                echo `date`" Destroying '$node_name'"
                vagrant destroy $node_name -f
            fi
        else
            echo `date`" '$node_name' failed provisioning, output follows:"
        fi
    else
        echo `date`" '$node_name' failed creation, output follows:"
    fi

    unset VAGRANT_NODE
    return $retval
}

# should run before exporting a machine
# $1 - node name
machine_cleanup() {
    local node_name=$1; shift
    tmp_ssh_config=`mktemp`
    vagrant ssh-config $node_name > $tmp_ssh_config
    scp -F $tmp_ssh_config `dirname $0`/$PREPARE_BOX $node_name:/tmp/ && \
        ssh -F $tmp_ssh_config $node_name "chmod +x /tmp/`basename $PREPARE_BOX` && sudo /tmp/`basename $PREPARE_BOX`"
    retval=$?
    rm -f $tmp_ssh_config

    # waiting for machine to shut down
    sleep 15

    return $?
}

######################
# chef-solo specific #
######################
# chef-solo provisioning
# $1 - node name
chef-solo_provision() {
    local node_name=$1; shift
    vagrant provision $node_name
}

#######################
# virtualbox specific #
#######################
# virtualbox pre export
# $1 - node name
virtualbox_pre_export() {
    local node_name=$1; shift
}

# runs after exporting a machine
# $1 - node name
virtualbox_export() {
    local node_name=$1; shift
    vagrant package $node_name --output $node_name.box
}

# specific implementation for virtualbox
# $1 - node name
virtualbox_post_export() {
    local node_name=$1; shift
    local box_file=$node_name.box
}

######################
# openstack specific #
######################
# openstack pre export
# $1 - node name
openstack_pre_export() {
    local node_name=$1; shift
}

# runs after exporting a machine
# $1 - node name
openstack_export() {
    local node_name=$1; shift
    # TODO TODO
}

# specific implementation for openstack
# $1 - node name
openstack_post_export() {
    local node_name=$1; shift
    # TODO TODO
}

# prints usage
usage() {
    echo "Usage: $0 [OPTIONS]... NODE_NAME"
    echo "Provisions a vagrant machine."
    echo "
Options:
  -p             Provider to provision with. Can be virtualbox
                 (default) or openstack.
  -t             Provisioner. Supports only chef-solo at the moment.
  -c             Clear (destroy) machine after provisioning it.
  -e             Export (vagrant package) machine after
                 provisioning it.
  -r             Number of times to retry VM creation.
  -C             If specified, performs a cleanup of the node (delete users,
                 etc)."
    exit 2
}

# main
# $1 - node name to provision
main() {
    # since we know that Vagrantfile is one directory below us, we might as
    # well change to it...
    test -f Vagrantfile || cd `dirname $0`/..

    local provider=$VAGRANT_DEFAULT_PROVIDER
    local provisioner="chef-solo"
    local clear="no"
    local export="no"
    local -i retry_max=1
    local -i cleanup=0

    while getopts ":hp:t:cer:C" opt; do
        case $opt in
            h)  usage
                ;;
            p)  provider=$OPTARG
                ;;
            t)  provisioner=$OPTARG
                ;;
            r)  retry_max=$OPTARG
                ;;
            c)  clear="yes"
                ;;
            e)  export="yes"
                ;;
            C)  cleanup=1
                ;;
            \?)
                usage
                ;;
        esac
    done

    shift $(($OPTIND -1))

    # initiate the provisioning
    local node_name=$1; shift
    [ x"$node_name" = x ] && usage

    provision_node $provider $provisioner $node_name $clear $export $retry_max $cleanup
}

main "$@"
