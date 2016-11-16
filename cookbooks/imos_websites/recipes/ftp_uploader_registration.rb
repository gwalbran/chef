#
# Cookbook Name:: imos_websites
# Recipe:: ftp_uploader_registration
#
# Copyright (C) 2015 IMOS
#
# All rights reserved - Do Not Redistribute
#

include_recipe "git"
include_recipe "imos_apache2::vhosts"
include_recipe "imos_apache2::php"

package "php5-pgsql"

application "ftp_uploader_registration" do
  path       node['imos_websites']['ftp_uploader_registration']['doc_root']
  repository node['imos_websites']['ftp_uploader_registration']['git_repo']
end

data_bag    = Chef::EncryptedDataBagItem.load("passwords", node['imos_websites']['ftp_uploader_registration']['data_bag'])
db_host     = data_bag['host']
db_name     = data_bag['database']
db_username = data_bag['username']
db_password = data_bag['password']

db_config = ::File.join(node['imos_websites']['ftp_uploader_registration']['doc_root'], "current", "config-db.php")
template db_config do
  source "ftp_uploader_registration/config-db.php.erb"
  variables ({
    :db_host     => db_host,
    :db_name     => db_name,
    :db_username => db_username,
    :db_password => db_password
  })
end
