#!/bin/bash -x

# Written by Dan Fruehauf <dan.fruehauf@utas.edu.au>

# script to prepare a machine before packaging with vagrant

# default root password
ROOT_PASSWORD=root

# users to not remove
USERS_IGNORE="vagrant backups"

# weird sudo environment set PATH!
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# remove ssh host identities, they should be recreated on reboot
remove_ssh_host_identities() {
    rm -f /etc/ssh/ssh_host_*

    # ubuntu is rather dumb, so we'll add something in rc.local for it
    # to recreate the keys on the next restart
    echo "#!/bin/bash" > /etc/rc.local
    echo "test -f /etc/ssh/ssh_host_rsa_key || dpkg-reconfigure openssh-server" >> /etc/rc.local
}

# clear network rules so box can boot cleanly
clear_udev_net_rules() {
    sed -i -r '/#VAGRANT-BEGIN/,/#VAGRANT-END/d' /etc/network/interfaces
    sed -i -e "\\#.*eth1.*#d" /etc/udev/rules.d/70-persistent-net.rules
    return 0
}

# remove all users except for the ones in $USERS_IGNORE
remove_users() {
    local user
    for user in `ls -1 /home | grep -v 'lost+found'`; do
        if ! echo $USERS_IGNORE | grep -q "\b$user\b"; then
            userdel -r -f $user
        fi
    done
    # userdel might return errors - we don't care!!
    return 0
}

# setup password for root user
setup_root_password() {
    echo root:$ROOT_PASSWORD | chpasswd
}

# clear history for root
clear_root_history() {
    > /root/.bash_history
}

# clear /tmp/
clear_tmp() {
    # might encounter some locked files, as chef-solo will be mounted there
    # run with --one-file-system so we don't delete our chef stuff
    rm -rf --one-file-system --preserve-root /tmp/*; true
}

# main
main() {
    remove_ssh_host_identities && \
    clear_udev_net_rules && \
    remove_users && \
    setup_root_password && \
    clear_root_history && \
    clear_tmp && \
    poweroff
}

main "$@"
