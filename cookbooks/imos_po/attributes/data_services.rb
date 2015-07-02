# data services repository and cronjobs management
default['imos_po']['data_services']['dir']    = "/var/lib/data-services"
default['imos_po']['data_services']['repo']   = "git@github.com:aodn/data-services.git"
default['imos_po']['data_services']['branch'] = "master"

# Groups of users who are allowed to run cronjobs
default['imos_po']['data_services']['cron_allowed_groups'] = [ 'projectofficer' ]
default['imos_po']['data_services']['cron_allowed_users']  = [ 'ftp', 'nobody' ]

# Enable/disable installation of the cronjobs and watches
default['imos_po']['data_services']['cronjobs'] = true
default['imos_po']['data_services']['watches']  = true

# Directories scripts are likely to access
default['imos_po']['data_services']['opendap_dir']   = '/mnt/opendap'
default['imos_po']['data_services']['public_dir']    = '/mnt/public'
default['imos_po']['data_services']['archive_dir']   = '/mnt/archive'
default['imos_po']['data_services']['incoming_dir']  = '/mnt/incoming'
default['imos_po']['data_services']['error_dir']     = '/mnt/err'
default['imos_po']['data_services']['graveyard_dir'] = '/mnt/graveyard'
default['imos_po']['data_services']['log_dir']       = '/var/log/data-services'

default['imos_po']['data_services']['owned_dirs'] = [
  node['imos_po']['data_services']['error_dir'],
  node['imos_po']['data_services']['graveyard_dir'],
  node['imos_po']['data_services']['log_dir']
]

# env file for data-services repository
default['imos_po']['data_services']['env'] = ::File.join(node['imos_po']['data_services']['dir'], "env")

# User to use when running cronjobs
default['imos_po']['data_services']['user']  = 'projectofficer'
default['imos_po']['data_services']['group'] = 'projectofficer'

# Event driven processing variables
default['imos_po']['watch_exec_wrapper']         = "/usr/local/bin/watch-exec-wrapper.sh"
default['imos_po']['watches']['syslog_facility'] = "local3"
default['imos_po']['data_services']['lib']       = ::File.join(node['imos_po']['data_services']['dir'], "lib", "common")

# When running in vagrant in dev mode, we will clone the repo from outside the node
default['imos_po']['data_services']['clone_repository'] = true

# Required packages
default['imos_po']['data_services']['packages'] = [ 'imagemagick', 'gdal-bin', 'sqlite3', 'heirloom-mailx', 'python-pip', 'python-dev', 'libnetcdf-dev', 'libhdf5-serial-dev', 'python-scipy', 'python-matplotlib', 'python-numpy', 'python-psycopg2', 'python-beautifulsoup', 'ipython', 'python-scipy' ]

# All required python plugins
default['imos_po']['data_services']['python']['plugins'] = [ 'netCDF4', 'OWSLib', 'Wicken', 'lxml', 'cf_units', 'requests', 'python-dateutil', 'six' ]

default['imos_po']['email_aliases'] = "/etc/incoming-aliases"
