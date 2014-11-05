#
# Cookbook Name:: nagios
# Recipe:: imos_client_mounts
#
# Copyright 2013, IMOS
#
# This recipe defines all the NRPE monitors for aodn mount points
#

# Define nrpe checks for mount points
if node['mounts'] && node['mounts']['mounts']
  node['mounts']['mounts'].each do |mount_point_entry|
    mount_point            = mount_point_entry['mount_point']
    # Normalize mount point, so we can create a filename with that name
    # /mnt/imos-t4 -> _mnt_imos-t4
    mount_point_normalized = mount_point.gsub(/[\/]/, '_')
    device                 = mount_point_entry['device']
    warning                = mount_point_entry['warning']  ? mount_point_entry['warning']  : "50"
    critical               = mount_point_entry['critical'] ? mount_point_entry['critical'] : "20"
    nagios_nrpecheck "check_disk_#{mount_point_normalized}" do
      command "#{node['nagios']['plugin_dir']}/check_disk -w #{warning} -c #{critical} -p #{mount_point}"
      action :add
    end
  end
end
