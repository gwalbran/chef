# Fix apt repositories to use main ones
sed -i -e 's#http://us.archive.ubuntu.com/ubuntu/#http://archive.ubuntu.com/ubuntu/#g' /etc/apt/sources.list
apt-get clean
apt-get -y update

# Install more packages
apt-get -y install curl nfs-common libxml2-dev libxslt1-dev zlib1g-dev \
    binutils-doc bison build-essential unzip gettext flex ncurses-dev lvm2 \
    auditd nagios-nrpe-server libnagios-plugin-perl nsca-client runit \
    vim

apt-get -y install libxft-dev libpng-dev libblas-dev liblapack-dev gfortran \
    python-dev python-pip python-psycopg2 libnetcdf-dev libhdf5-serial-dev

pip install numpy==1.10.1
pip install netCDF4==1.2.1
pip install scipy==0.9.0
pip install matplotlib==1.1.1

exit
