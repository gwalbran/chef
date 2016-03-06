#
# Cookbook Name:: imos_po
# Recipe:: default
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#

# You should have the projectofficer group defined
if ! node['imos_users'] ||
  ! node['imos_users']['groups'] ||
  ! node['imos_users']['groups'].include?("projectofficer")
  Chef::Application.fatal!("Must have projectofficer group defined in your node")
end

include_recipe "imos_po::netcdf_nco"
