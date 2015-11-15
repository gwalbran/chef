#
# Cookbook Name:: imos_websites
# Recipe:: depth_service
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

package 'libdbd-pgsql'
package 'libdbi-perl'
package 'libcgi-simple-perl'

directory node['imos_websites']['depth_service']['base'] do
  owner     node['apache']['user']
  group     node['apache']['group']
  mode      00755
  recursive true
end

data_bag = Chef::EncryptedDataBagItem.load('passwords', 'depthservice')
database_host = data_bag['host']
database_name = data_bag['database']
database_user = data_bag['username']
database_pass = data_bag['password']
database_schema = data_bag['schema']

template ::File.join(node['imos_websites']['depth_service']['base'], "depth.xml") do
  source    "depth_service/depth.xml.erb"
  owner     node['apache']['user']
  group     node['apache']['group']
  mode      00755
  variables ({
    :database_host => database_host,
    :database_name => database_name,
    :database_user => database_user,
    :database_pass => database_pass,
    :database_schema => database_schema
  })
end
