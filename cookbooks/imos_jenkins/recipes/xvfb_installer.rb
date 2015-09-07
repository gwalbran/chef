#
# Cookbook Name:: jenkins
# Recipe:: xvfb_installer
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#
include_recipe 'xvfb'

filename = 'org.jenkinsci.plugins.xvfb.XvfbBuildWrapper.xml'
template File.join(node['jenkins']['master']['home'], filename) do
  source   "#{filename}.erb"
  owner    node['jenkins']['master']['user']
  group    node['jenkins']['master']['group']
  mode     '0644'
  notifies :restart, 'service[jenkins]', :delayed
end
