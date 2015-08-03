#
# Cookbook Name:: nagios
# Recipe:: imos_client_input
#
# Copyright 2015, IMOS
#
# This recipe defines all the NRPE monitors for input processing
#

if node.recipe?("imos_po::data_services")
  node['imos_po']['data_services']['monitored_watch_jobs'].each do |job|
    error_dir = ::File.join(node['imos_po']['data_services']['error_dir'], job)
    nagios_nrpecheck "check_input_#{job}" do
      command "#{node['nagios']['plugin_dir']}/check_file_count -r -c 1 -w 1 -d #{error_dir}"
      action :add
    end
  end
end

