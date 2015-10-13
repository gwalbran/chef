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

# Node definition should override this attribute
default['imos_po']['data_services']['monitored_watch_jobs'] = []

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
default['imos_po']['data_services']['packages'] = [
  'bc',
  'gdal-bin',
  'heirloom-mailx',
  'imagemagick',
  'ipython',
  'lftp',
  'libhdf5-serial-dev',
  'libnetcdf-dev',
  'mdbtools'
  'python-beautifulsoup',
  'python-dev',
  'python-matplotlib',
  'python-numpy',
  'python-pip',
  'python-psycopg2',
  'python-scipy',
  'python-scipy',
  'sqlite3',
]

# All required python plugins
default['imos_po']['data_services']['python']['packages'] = [
  { 'name' => 'netCDF4' },
  { 'name' => 'OWSLib' },
  { 'name' => 'Wicken' },
  { 'name' => 'lxml' },
  { 'name' => 'cf_units' },
  { 'name' => 'requests' },
  { 'name' => 'python-dateutil' },
  { 'name' => 'six' },
  { 'name' => 'petulant-bear', 'version' => '0.1.3' },
  { 'name' => 'PyYAML' }
]

default['imos_po']['email_aliases'] = "/etc/incoming-aliases"

default['imos_po']['s3']['password_data_bag'] = "s3_imos_data"
default['imos_po']['s3']['bucket']            = "s3://imos-data"
default['imos_po']['s3']['config_file']       = ::File.join(node['imos_po']['data_services']['dir'], "s3cfg")

default['imos_po']['mailx']['password_data_bag'] = nil
default['imos_po']['mailx']['config_file'] = ::File.join(node['imos_po']['data_services']['dir'], "mailrc")
