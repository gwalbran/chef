default['imos_vsftpd']['anon_root']  = '/mnt/ftp-root'
default['imos_vsftpd']['local_root'] = '/var/lib/ftp'

default['imos_vsftpd']['ftp_users']['data_bags'] = []

default['imos_vsftpd']['ftp_dir_tree']['data_bags'] = []
default['imos_vsftpd']['ftp_dir_tree']['root'] = '/var/lib/ftp'

default['imos_vsftpd']['ftp_dir_tree']['owner'] = "ftp"
default['imos_vsftpd']['ftp_dir_tree']['group'] = "users"
