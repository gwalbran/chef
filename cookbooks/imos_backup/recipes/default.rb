#
# Cookbook Name:: backup
# Recipe:: default
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#

# Create the backup user (IMOS recipe)
include_recipe "imos_users::backups"

# Include the backup rock recipe
include_recipe "backup"

# DF: UGLY BUT HARMLESS AND DOCUMENTED
# Have a dummy file in the local backups dir, that is so even if there are no
# backups going, pulling of backups will not fail. Pulling of backups will try
# to pull node[:backup][:backup_dir]/*, so if we go with the '/*' suffix, we
# better have something there so it doesn't fail.
# Have a look at the template model_rsync_pull.rb.erb
file "#{node[:backup][:backup_dir]}/dummy" do
  mode 0644
  action :touch
end

# tmp_dir might be on NFS and we might not be able to set its permissions to
# the backup user, so just create it. chmod should succeed
directory node[:imos_backup][:tmp_dir] do
  mode      0777
  recursive true
end

# Try to chown the directory, don't fail if we cannot
begin
  Mixlib::shell_out("chown #{node[:backup][:username]}:#{node[:backup][:group]} #{node[:backup][:backup_dir]}") 
rescue
  Chef::Log.warn("Could not chown directory '#{node[:imos_backup][:tmp_dir]}', but we'll proceed anyway")
end

# Temporary and status directories
[
  node[:imos_backup][:status_dir],
  node[:imos_backup][:lock_dir]
].each do |d|
  directory d do
    mode      0755
    owner     node[:backup][:username]
    group     node[:backup][:group]
    recursive true
  end
end

# Install logrotate
logrotate_app "backups" do
  cookbook "logrotate"
  path "#{node[:backup][:log_dir]}/*.log"
  options ["missingok", "compress", "notifempty"]
  frequency "daily"
  rotate 7
  nocreate
end

# Script to run all backups
template "#{node[:backup][:base_dir]}/backup" do
  source "backup.erb"
  owner node[:backup][:username]
  group node[:backup][:group]
  mode 0755
end

# schedule using cron
if node[:imos_backup][:restore][:allow]
  Chef::Log.warn("Not installing backup cronjob as restore is switched on")
else
  cron "backup_all" do
    minute    node[:imos_backup][:cron][:minute]
    hour      node[:imos_backup][:cron][:hour]
    day       node[:imos_backup][:cron][:day]
    month     node[:imos_backup][:cron][:month]
    weekday   node[:imos_backup][:cron][:weekday]
    command   "#{node[:backup][:base_dir]}/backup > /dev/null"
    user      node[:backup][:username]
  end
end

# Allow sudo access for backup user, useful for running tar backups
sudo 'backups' do
  user      node[:backup][:username]
  runas     'root'
  commands  ['/bin/tar']
  host      "ALL"
  nopasswd  true
end

# Plug the imos_pgsql.sh plugin
template ::File.join(node[:backup][:bin_dir], "modules", "backup", "imos_pgsql.sh") do
  source "imos_pgsql.sh.erb"
  owner  "#{node[:backup][:username]}"
  group  "#{node[:backup][:group]}"
  mode   0644
end

# Install restore recipe only if allowed
if node[:imos_backup][:restore][:allow]
  include_recipe "imos_backup::restore"
end
