#!/bin/bash

# returns a list of all nodes in given environment
# $1 - environment
get_nodes_in_environment() {
    local environment=$1; shift

    local nodes

    local file
    for file in nodes/*.json; do
        if grep chef_environment $file | grep -q $environment; then
            local node=`basename $file | cut -d. -f1`
            nodes="$nodes $node"
        fi
    done

    echo $nodes
}

# main
main() {
    get_nodes_in_environment $1
}

main "$@"
