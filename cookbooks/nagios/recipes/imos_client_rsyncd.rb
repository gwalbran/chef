#
# Cookbook Name:: nagios
# Recipe:: imos_client_tomcat
#
# Copyright 2013, IMOS
#
# This recipe defines all the NRPE monitors for tomcat monitoring
#

# Define nrpe checks for rsync
if node['rsyncd'] && node['rsyncd']['service']
  nagios_nrpecheck "check_rsyncd" do
    command "#{node['nagios']['plugin_dir']}/check_tcp -H #{node['fqdn']} -p 873"
    action :add
  end
end

