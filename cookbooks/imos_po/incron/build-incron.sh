#!/bin/bash

set -e

main() {
    rm -rf incron*
    apt-get source incron
    local incron_src_dir=`ls -1d */ | grep incron`

    cp `dirname $0`/patches/* $incron_src_dir/debian/patches/
    ls -1 `dirname $0`/patches/* | xargs -n1 basename >> $incron_src_dir/debian/patches/series

    local new_changelog=`mktemp`
    cat <<EOF > $new_changelog
incron (0.5.10-2~ubuntu12.04.1) precise-backports; urgency=medium

  * Wait after forking, prevent fork bomb

 -- Dan Fruehauf <dan.fruehauf@utas.edu.au>  Wed, 14 Oct 2015 18:14:04 +0100

EOF
    cat $incron_src_dir/debian/changelog >> $new_changelog
    mv $new_changelog $incron_src_dir/debian/changelog

    (cd $incron_src_dir && dpkg-buildpackage -B -nc)
}

main "$@"
