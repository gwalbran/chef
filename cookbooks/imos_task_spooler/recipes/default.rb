#
# Cookbook Name:: imos_task_spooler
# Recipe:: default
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#

# Download and install task spooler
task_spooler_url = node['imos_task_spooler']['url']
package_name     = ::File.basename(task_spooler_url)
cache_file_path  = ::File.join(Chef::Config[:file_cache_path], package_name)

remote_file cache_file_path do
  source task_spooler_url
  mode   0644
  not_if { ::File.exists?(cache_file_path) }
end

dpkg_package package_name do
  source cache_file_path
  action :install
end

# Install tsp-if-not-queued wrapper script
cookbook_file node['imos_task_spooler']['tsp_if_not_queued'] do
  source ::File.basename(node['imos_task_spooler']['tsp_if_not_queued'])
  owner  'root'
  group  'root'
  mode   0755
end
