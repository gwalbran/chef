#
# Cookbook Name:: monitoring
# Recipe:: imos_client_system
#
# Copyright 2013, IMOS
#
# This recipe defines the necessary NRPE commands for base system monitoring
#

# Check for high load.  This check defines warning levels and attributes
nagios_nrpecheck "check_load" do
  command "#{node['nagios']['plugin_dir']}/check_load"
  warning_condition "86,18,14.6"
  critical_condition "86,86,86"
  action :add
end

# Check all non-NFS/tmp-fs disks.
nagios_nrpecheck "check_disks" do
  command "#{node['nagios']['plugin_dir']}/check_disk"
  warning_condition "8%"
  critical_condition "5%"
  parameters "-A -x /dev/shm -X nfs -X fuse.sshfs -X tracefs -i /boot"
  action :add
end

# Check for excessive users.  This command relies on the service definition to
# define what the warning/critical levels and attributes are
nagios_nrpecheck "check_users" do
  command "#{node['nagios']['plugin_dir']}/check_users"
  warning_condition "15"
  critical_condition "30"
  action :add
end

# Check number of processes
nagios_nrpecheck "check_total_procs" do
  command "#{node['nagios']['plugin_dir']}/check_procs"
  warning_condition "400"
  critical_condition "600"
  action :add
end

# Check CPU (via iostat, so we get cpu steal time)
nagios_nrpecheck "check_cpu" do
  command "#{node['nagios']['plugin_dir']}/check_cpu_stats.sh -w 101 -c 101"
  action :add
end

# Check memory, we don't really need alerts for that, just graphs
nagios_nrpecheck "check_mem" do
  command "#{node['nagios']['plugin_dir']}/check_linux_stats.pl -M -u % -c 100,100 -w 100,100"
  action :add
end

# Check disk IO
nagios_nrpecheck "check_disk_io" do
  command "#{node['nagios']['plugin_dir']}/check_linux_stats.pl -I -u BYTES -w 40000000,40000000 -c 60000000,60000000"
  action :add
end

# Check network
nagios_nrpecheck "check_net" do
  command "#{node['nagios']['plugin_dir']}/check_linux_stats.pl -N -w 40000000 -c 60000000"
  action :add
end

