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

# Try and install pip module, avoid network problems which are common when
# installing python packages by retrying up to a few times
# $1 - python module to install
pip_install_retry() {
    local python_module=$1; shift
    for i in `seq 1 5`; do
        pip install $python_module && return
        sleep 60
    done

    return 1
}

PYTHON_MODULES="numpy==1.10.1 netCDF4==1.2.1 scipy==0.9.0 matplotlib==1.1.1"
for python_module in $PYTHON_MODULES; do
    pip_install_retry $python_module || exit 1
done

exit
