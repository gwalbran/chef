# Always allow vagrant to sudo without password
echo "vagrant ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
sed -i -e 's/%sudo ALL=(ALL) ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers

# Fix apt repositories to use main ones
sed -i -e 's#http://us.archive.ubuntu.com/ubuntu/#http://archive.ubuntu.com/ubuntu/#g' /etc/apt/sources.list

apt-get -y update

# Install more packages
apt-get -y install curl nfs-common libxml2-dev libxslt1-dev zlib1g-dev \
    binutils-doc bison build-essential unzip gettext flex ncurses-dev lvm2 \
    auditd nagios-nrpe-server libnagios-plugin-perl nsca-client runit

# Setup root password to be 'root'
echo root:root | chpasswd

exit
