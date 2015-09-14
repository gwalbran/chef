apt-get -y update

# Install more packages
apt-get -y install curl nfs-common libxml2-dev libxslt1-dev zlib1g-dev \
    binutils-doc bison build-essential unzip gettext flex ncurses-dev lvm2 \
    auditd nagios-nrpe-server libnagios-plugin-perl nsca-client runit \
    vim

exit
