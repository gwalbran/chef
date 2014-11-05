#
# Cookbook Name:: sofs
# Recipe:: default
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'git'
include_recipe "imos_apache2::vhosts"

application "sofs" do
  path node[:sofs][:doc_root]
  repository "https://github.com/aodn/sofs.git"
end

directory node[:sofs][:log_dir] do
  owner "root"
  group "root"
  mode 00777
  action :create
end

include_recipe "imos_core::lftp"

sofs_ftp_creds = Chef::EncryptedDataBagItem.load("passwords", "sofs")
# Allow override of attributes from data bag
sofs_ftp_host = sofs_ftp_creds['host'] || node[:sofs][:host]
sofs_ftp_src_dir = sofs_ftp_creds['src_dir'] || node[:sofs][:src_dir]
sofs_ftp_dest_dir = sofs_ftp_creds['dest_dir'] || node[:sofs][:dest_dir]

lftp_command = "lftp -e 'mirror -e --parallel=10 --log=#{node[:sofs][:log_file]} #{sofs_ftp_src_dir} #{sofs_ftp_dest_dir} ; quit' -u #{sofs_ftp_creds['username']},#{sofs_ftp_creds['password']} #{sofs_ftp_host}"

cron "lftp-sofs-images" do
  hour "*/4"
  minute "15"
  command lftp_command
end

execute "lftp-sofs-images-run-once" do
  command lftp_command
  only_if { Dir["#{sofs_ftp_dest_dir}/*"].empty? }
end
