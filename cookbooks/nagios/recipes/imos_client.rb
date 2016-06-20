#
# Cookbook Name:: nagios
# Recipe:: imos_client
#
# Copyright 2013, IMOS
#
# This recipe defines all the NRPE monitors for IMOS servers
#

include_recipe "nagios::client"

# We'll need the perl linux statistics module
# sysstat is needed for iostat
# Nagios perl plugin for check_sql
%w{
  libsys-statistics-linux-perl
  sysstat
  libnagios-plugin-perl
  libdbd-pgsql
  libdbi-perl
  libdbd-pg-perl
}.each do |pkg|
  package pkg
end

# Declare all nagios plugins we'll download from the web
nagios_plugins_3rd_party = [
]

nagios_plugins_3rd_party.each do |plugin_pair|
  plugin_name = plugin_pair[0]
  plugin_url  = plugin_pair[1]
  remote_file "#{node['nagios']['plugin_dir']}/#{plugin_name}" do
    source plugin_url
    mode 00755
  end
end

# Sync with custom scripts
remote_directory "#{node['nagios']['plugin_dir']}" do
  source "plugins"
  files_owner node['nagios']['user']
  files_group node['nagios']['group']
  files_mode 00755
end

# Include all IMOS specific recipes
include_recipe "nagios::imos_client_mounts"
include_recipe "nagios::imos_client_system"
include_recipe "nagios::imos_client_backup"
include_recipe "nagios::imos_client_need_reboot"
include_recipe "nagios::imos_client_postgresql"
include_recipe "nagios::imos_client_tomcat"
include_recipe "nagios::imos_client_input"
include_recipe "nagios::imos_client_talend"
include_recipe "nagios::imos_client_rsyncd"
include_recipe "nagios::imos_client_vsftpd"
include_recipe "nagios::imos_client_webapp"
include_recipe "nagios::imos_client_remote_sync"

# Install nagios NSCA client
package "nsca-client" do
  package_name "nsca-client"
  action :install
end

# NSCA configuration
nsca_password = Chef::EncryptedDataBagItem.load("passwords", "nsca")['password']
template "#{node['nagios']['nsca']['conf_dir']}/send_nsca.cfg" do
  source "send_nsca.cfg.erb"
  owner node['nagios']['user']
  group node['nagios']['group']
  mode 00444
  variables(:nsca_password => nsca_password)
end

# Install NSCA chef handler
remote_directory node['chef_handler']['handler_path'] do
  source 'handlers'
  owner node['chef_handler']['root_user']
  group node['chef_handler']['root_group']
  mode "0755"
  recursive true
  action :create
end

# Chef passive (NSCA) check
chef_handler "Imos::NSCAHandler" do
  source "#{node['chef_handler']['handler_path']}/nsca_handler"
  supports :report => true, :exception => true
  action :enable
end
