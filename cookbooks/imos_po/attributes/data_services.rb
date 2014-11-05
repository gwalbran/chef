# data services repository and cronjobs management
default['imos_po']['data_services']['dir']    = "/var/lib/data-services"
default['imos_po']['data_services']['repo']   = "git@github.com:aodn/data-services.git"
default['imos_po']['data_services']['branch'] = "master"

# Groups of users who are allowed to run cronjobs
default['imos_po']['data_services']['cron_allowed_groups'] = [ 'projectofficer' ]
default['imos_po']['data_services']['cron_allowed_users']  = [ 'ftp', 'nobody' ]

# Enable/disable installation of the cronjobs
default['imos_po']['data_services']['cronjobs'] = true

# Directories scripts are likely to access
default['imos_po']['data_services']['opendap_dir']  = '/mnt/opendap'
default['imos_po']['data_services']['public_dir']   = '/mnt/public'
default['imos_po']['data_services']['archive_dir']  = '/mnt/archive'
default['imos_po']['data_services']['incoming_dir'] = '/mnt/incoming'
