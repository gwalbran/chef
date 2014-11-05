#
# Cookbook Name:: nagios
# Recipe:: imos_pnp4nagios
#
# Copyright 2013, IMOS
#
# This recipe defines all the NRPE monitors for IMOS servers
#

# Download all pnp4nagios templates
remote_directory ::File.join(node['nagios']['server']['pnp4nagios_local_dir'], "templates") do
  source      'pnp4nagios/templates'
  files_owner 'root'
  files_group 'root'
  files_mode  00644
end
