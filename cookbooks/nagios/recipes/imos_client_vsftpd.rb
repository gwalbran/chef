#
# Cookbook Name:: nagios
# Recipe:: imos_client_vsftpd
#
# Copyright 2013, IMOS
#
# This recipe defines all the NRPE monitors for vsftpd
#

# Check all IMOS talend jobs defined on node
if node.run_list.include?("role[ftp_server]")
  # nrpe check per job
  nagios_nrpecheck "check_ftp_dirs" do
    command "#{node['nagios']['plugin_dir']}/check_ftp_dirs"
    action :add
  end
end

