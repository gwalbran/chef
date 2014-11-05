node.set['network']['public_ipv4'] = "test_public_ipv4"

node.set['imos_vsftpd']['ftp_dir_tree']['root'] = '/tmp/ftp_dir_tree'
node.set['imos_vsftpd']['ftp_dir_tree']['data_bags'] = [ "ftp_dir_tree/*" ]

include_recipe 'imos_vsftpd::default'
include_recipe 'imos_vsftpd::ftp_dir_tree'
