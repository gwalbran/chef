#
# Cookbook Name:: vsftpd
# Recipe:: ftp_dir_tree
#
# Copyright 2013, IMOS
#

root = node['imos_vsftpd']['ftp_dir_tree']['root']

node['imos_vsftpd']['ftp_dir_tree']['data_bags'].each do |data_bag_pattern|

  # break something like 'ftp_dir_tree/*' to 'ftp_dir_tree' and '*'
  # or something like 'ftp_dir_tree/AATAMS to 'ftp_dir_tree' and 'AATAMS
  data_bag_pattern_name     = ::File.dirname(data_bag_pattern)
  data_bag_pattern_wildcard = ::File.basename(data_bag_pattern)

  search("#{data_bag_pattern_name}", "id:#{data_bag_pattern_wildcard}").each do |data_bag|
    directory = File.join(root, data_bag['directory'])
    Chef::Log.info("Creating FTP directory '#{directory}'")

    directory directory do
      owner     data_bag['owner'] || node['imos_vsftpd']['ftp_dir_tree']['owner']
      group     data_bag['group'] || node['imos_vsftpd']['ftp_dir_tree']['group']
      mode      data_bag['mode']  || node['imos_vsftpd']['ftp_dir_tree']['mode']
      recursive true
    end

  end

end
