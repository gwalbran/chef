#
# Cookbook Name:: imos_devel
# Recipe:: vagrant
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Recipe to install vagrant
#

is_vagrant_in_correct_version = "dpkg-query -W -f='${Version}' vagrant | grep #{node['imos_devel']['vagrant']['version']}"
dpkg_package 'vagrant' do
  action :purge
  not_if is_vagrant_in_correct_version
end

# Install vagrant.
remote_file File.join(Chef::Config[:file_cache_path], node['imos_devel']['vagrant']['package_name']) do
  source node['imos_devel']['vagrant']['source_url']
  mode 0644
  checksum node['imos_devel']['vagrant']['source_checksum']
  action :create_if_missing
end

dpkg_package node['imos_devel']['vagrant']['package_name'] do
  source File.join(Chef::Config[:file_cache_path], node['imos_devel']['vagrant']['package_name'])
  not_if is_vagrant_in_correct_version
end

include_recipe "imos_devel::vagrant_plugins"
