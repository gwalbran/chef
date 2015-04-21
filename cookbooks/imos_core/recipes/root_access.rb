#
# Cookbook Name:: imos_core
# Recipe:: root_access
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

directory "/root/.ssh" do
  mode 00755
end

root_data_bag = Chef::EncryptedDataBagItem.load("passwords", "root")

template "/root/.ssh/authorized_keys" do
  source "root_authorized_keys.erb"
  mode   00644
  owner  "root"
  group  "root"
  variables({
    :ssh_keys => root_data_bag['ssh_keys']
  })
end

# Change root password override EVERYTHING
execute "root password" do
  command "usermod -p '#{root_data_bag['password']}' root"
  not_if {
    current_root_password=`getent shadow root`.split(':')[1]
    current_root_password == root_data_bag['password']
  }
end
