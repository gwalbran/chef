#
# Cookbook Name:: jenkins
# Recipe:: xvfb_installer
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#
include_recipe 'xvfb'

file File.join(node['jenkins']['master']['home'], 'org.jenkinsci.plugins.xvfb.XvfbBuildWrapper.xml') do
  owner node['jenkins']['master']['user']
  group node['jenkins']['master']['group']
  mode  '0644'
end
