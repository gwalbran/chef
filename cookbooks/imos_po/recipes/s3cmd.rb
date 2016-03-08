#
# Cookbook Name:: imos_po
# Recipe:: s3cmd
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#
# s3cmd credentials

s3_data_bag = Chef::EncryptedDataBagItem.load("passwords", node['imos_po']['s3']['password_data_bag'])
s3cmd_config node['imos_po']['s3']['config_file'] do
  owner      node['imos_po']['data_services']['user']
  access_key s3_data_bag['access_key_id']
  secret_key s3_data_bag['secret_access_key']
end

cookbook_file "/usr/local/bin/s3lsv" do
  mode 00755
end
