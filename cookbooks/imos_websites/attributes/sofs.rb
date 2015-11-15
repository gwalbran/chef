default['imos_websites']['sofs']['doc_root'] = '/var/www/sofs'
default['imos_websites']['sofs']['log_dir']  = '/var/log/sofs'
default['imos_websites']['sofs']['log_file'] = ::File.join(node['imos_websites']['sofs']['log_dir'], "sofs-lftp.log")
default['imos_websites']['sofs']['host']     = 'ftp.bom.gov.au'
default['imos_websites']['sofs']['src_dir']  = '/register/bom404/outgoing/IMOS/IMG'
default['imos_websites']['sofs']['dest_dir'] = ::File.join(node['imos_websites']['sofs']['doc_root'], "current", "images")
default['imos_websites']['sofs']['git_repo'] = 'https://github.com/aodn/sofs.git'
