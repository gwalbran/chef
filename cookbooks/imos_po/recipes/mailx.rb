#
# Cookbook Name:: imos_po
# Recipe:: mailx
#
# Copyright (C) 2015 IMOS
#
# All rights reserved - Do Not Redistribute
#
# mailx credentials


mailx_config = ""
if node['imos_po']['mailx']['password_data_bag']
  mailx_data_bag = Chef::EncryptedDataBagItem.load("passwords", node['imos_po']['mailx']['password_data_bag'])
  mailx_config  = "set smtp=#{mailx_data_bag['host']}:#{mailx_data_bag['port']}\n"
  mailx_config += "set smtp-auth-user=#{mailx_data_bag['username']}\n"
  mailx_config += "set smtp-auth-password=#{mailx_data_bag['password']}\n"
end

file node['imos_po']['mailx']['config_file'] do
  owner   node['imos_po']['data_services']['user']
  content mailx_config
end
