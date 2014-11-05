#
# Cookbook Name:: sofs
# Attributes:: sofs
#

set[:sofs][:doc_root] = '/var/www/sofs'
set[:sofs][:log_dir] = '/var/log/sofs'
set[:sofs][:log_file] = "#{node[:sofs][:log_dir]}/sofs-lftp.log"
set[:sofs][:host] = 'ftp.bom.gov.au'
set[:sofs][:src_dir] = '/register/bom404/outgoing/IMOS/IMG'
set[:sofs][:dest_dir] = "#{node[:sofs][:doc_root]}/current/images"
