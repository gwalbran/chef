#
# Cookbook Name:: imos_core
# Recipe:: gdal
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

# Install GDAL from jenkins
gdal_filename  = File.basename(node['imos_core']['gdal']['url'])
gdal_full_path = File.join(Chef::Config[:file_cache_path], gdal_filename)

remote_file gdal_full_path do
  source   node['imos_core']['gdal']['url']
  mode     0644
  action   :create_if_missing
end

dpkg_package gdal_full_path do
  source gdal_full_path
end

