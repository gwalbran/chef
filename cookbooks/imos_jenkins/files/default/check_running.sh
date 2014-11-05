#!/bin/bash

# Checks the Portal is running (and is of a particular version).

url=$1
version=$2

wget -q -O - $url | grep -q $version
exitCode=$?

if [[ $exitCode -eq 0 ]]; then
    echo "Running at URL '$url' with version '$version'";
else
    echo "Error: not running at URL '$url' with version '$version'";
fi

exit $exitCode;

