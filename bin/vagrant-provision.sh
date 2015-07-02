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
        if [ `uname` != "Linux" ]; then
            vagrant up $node_name --no-provision --provider=$provider  # No timeout on *BSD
        else
            timeout 2h vagrant up $node_name --no-provision --provider=$provider
        fi
    done
}


# provision a node
# $1 - provider
# $2 - node name
# $3 - clear
# $4 - retry_max
provision_node() {
    local provider=$1; shift
    local node_name=$1; shift
    local clear=$1; shift
    local retry_max=$1; shift

    # export VAGRANT_NODE=nodes/${node_name}.json
    # ! test -f $VAGRANT_NODE && echo "Node '$VAGRANT_NODE' does not exist in configuration, check nodes/*" && exit 3

    local -i retval=0

    _lock

    create_node $node_name $provider $retry_max

    _unlock
    retval=$?

    if [ $retval -eq 0 ]; then
        echo `date`" Provisioning '$node_name'..."
        vagrant provision $node_name
        retval=$?

        if [ $retval -eq 0 ]; then
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

# prints usage
usage() {
    echo "Usage: $0 [OPTIONS]... NODE_NAME"
    echo "Provisions a vagrant machine."
    echo "
Options:
  -p             Provider to provision with. Can be virtualbox
                 (default) or openstack.
  -c             Clear (destroy) machine after provisioning it.
  -r             Number of times to retry VM creation."
    exit 2
}

# main
# $1 - node name to provision
main() {
    # since we know that Vagrantfile is one directory below us, we might as
    # well change to it...
    test -f Vagrantfile || cd `dirname $0`/..

    local provider=$VAGRANT_DEFAULT_PROVIDER
    local clear="no"
    local -i retry_max=1

    while getopts ":hp:cr:" opt; do
        case $opt in
            h)  usage
                ;;
            p)  provider=$OPTARG
                ;;
            r)  retry_max=$OPTARG
                ;;
            c)  clear="yes"
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

    provision_node $provider $node_name $clear $retry_max
}

main "$@"
