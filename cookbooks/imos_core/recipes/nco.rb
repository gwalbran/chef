#
# Cookbook Name:: imos_core
# Recipe:: nco
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

# Install NCO from jenkins
nco_filename  = File.basename(node['imos_core']['nco']['url'])
nco_full_path = File.join(Chef::Config[:file_cache_path], nco_filename)

remote_file nco_full_path do
  source   node['imos_core']['nco']['url']
  mode     0644
  action   :create_if_missing
end

%w{ libudunits2-0 libgsl0ldbl libnetcdf6 }.each do |pkg|
  package pkg
end

dpkg_package nco_full_path do
  source nco_full_path
end

