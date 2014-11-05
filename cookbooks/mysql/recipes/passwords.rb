#
# Cookbook Name:: mysql
# Recipe:: passwords
#
# Copyright 2012, IMOS
#
# All rights reserved - Do Not Redistribute
#

begin
  mysql_creds = Chef::EncryptedDataBagItem.load("passwords", "mysql")

  node.set['mysql']['server_debian_password'] = mysql_creds["password"]
  node.set['mysql']['server_root_password']   = mysql_creds["password"]
  node.set['mysql']['server_repl_password']   = mysql_creds["password"]
rescue => error
  Chef::Log.warn("Data bag passwords mysql not found")
end
