#
# Cookbook Name:: nagios
# Recipe:: imos_client_oceancurrent
#
# Copyright 2013, IMOS
#
# This recipe defines a NRPE monitor for oceancurrent
#

# Probe nodes with oceancurrent (only 5-nsp-mel at the time of writing this)
if node['nagios'] && node['nagios']['remote_sync_data_bags']
  node['nagios']['remote_sync_data_bags'].each do |remote_sync_data_bag_name|

    data_bag = Chef::DataBagItem.load("nagios_remote_sync", remote_sync_data_bag_name)

    name               = data_bag['id']
    warning_threshold  = data_bag['warning_threshold']  || node['nagios']['remote_sync']['warning_threshold']
    critical_threshold = data_bag['critical_threshold'] || node['nagios']['remote_sync']['critical_threshold']
    monitored_file     = data_bag['monitored_file']

    nagios_nrpecheck "check_remote_sync_#{name}" do
      command "#{node['nagios']['plugin_dir']}/check_file_age -w #{warning_threshold} -c #{critical_threshold} #{monitored_file}"
      action :add
    end
  end
end
