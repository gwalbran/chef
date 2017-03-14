#
# Cookbook Name:: imos_core
# Recipe:: unattended_upgrades
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

include_recipe "unattended_upgrades"

# Add additional MOS configuration for unattended upgrades
template node['imos_core']['unattended_upgrade_conf_file'] do
  source '51imos-unattended-upgrades.erb'
  owner 'root'
  group 'root'
  mode '0644'
end
