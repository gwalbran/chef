#
# Cookbook Name:: nagios
# Recipe:: imos_client_backup
#
# Copyright 2013, IMOS
#
# This recipe defines all the NRPE monitors for tomcat monitoring
#

# Check backup status
if node.run_list.include?('role[backup]')
  nagios_nrpecheck "check_backup" do

    # override for how long a backup is valid on a system
    if node['imos_backup']['hours_valid_for']
      backup_valid_hours = "-H #{node['imos_backup']['hours_valid_for']}"
    end

    command "#{node['nagios']['plugin_dir']}/check_backup -d #{node[:imos_backup][:status_dir]} #{backup_valid_hours}"
    action :add
  end
end

# If this is a backup server, it'll get also a check per host it'll backup
# So iterate on all nodes and add them

# Search for all nodes that have backup defined for them
backup_nodes = search(:node, "fqdn:*").select {|n| n['run_list'].include?('role[backup]')}

# Iterate on those nodes and create NRPE checks for them
if node.run_list.include?("recipe[imos_backup::server]")
  backup_nodes.each do |backup_node|
    # Will usually be the FQDN of the node
    backup_host_name = node['nagios']['server']['normalize_hostname'] ? backup_node[node['nagios']['host_name_attribute']].downcase : backup_node[node['nagios']['host_name_attribute']]

    # Add NRPE command for each host that this host will pull a backup from
    nagios_nrpecheck "check_backup_#{backup_host_name}" do
      command "#{node['nagios']['plugin_dir']}/check_backup -d #{node[:imos_backup][:status_dir]}/#{backup_host_name}"
      action :add
    end
  end
end
