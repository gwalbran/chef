#
# Cookbook Name:: monitoring
# Recipe:: imos_client_system
#
# Copyright 2013, IMOS
#
# This recipe defines the necessary NRPE commands for base system monitoring
#

# Check for high load.  This check defines warning levels and attributes
nagios_nrpecheck "check_need_reboot" do
  command "#{node['nagios']['plugin_dir']}/check_file_exists -r /var/run/reboot-required"
  action :add
end

