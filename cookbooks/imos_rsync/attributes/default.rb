# Default uid/gid for uploaded files
default['imos_rsync']['uid'] = "nobody"
default['imos_rsync']['gid'] = "nogroup"

# Max connections per serve
default['imos_rsync']['max_connections'] = 5

# Logging directory
default['imos_rsync']['log_dir']      = "/var/log/rsyncd"
default['imos_rsync']['incoming_dir'] = "/var/lib/incoming"

# User for chroot rsync uploads
default['imos_rsync']['user'] = 'rsync'
# Be part of 'users' group so you rsync_chroot can share directories with FTP
default['imos_rsync']['group'] = 'users'

# Create or not destination directories for imos_rsync::chroot. Usually
# ftp_dir_tree will create them
default['imos_rsync']['create_directories'] = false

default['imos_rsync']['users'] = []
default['imos_rsync']['serve'] = []
