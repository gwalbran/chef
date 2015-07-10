#
# Cookbook Name:: talend
# Recipe:: trigger
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Triggers the correct harvester base on data bags regex

package 'ruby1.9.3'

cookbook_file node['talend']['trigger']['bin'] do
  owner  node['talend']['user']
  group  node['talend']['user']
  source "talend-trigger"
  mode   00755
end
