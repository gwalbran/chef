#
# Cookbook Name:: backup
# Recipe:: restore
#
# Copyright (C) 2014 IMOS
#
# All rights reserved - Do Not Redistribute
#

package 'dialog'

# This is not an attribute as we want to evaluate it after
# `[:backup][:base_dir]` was evaluated
restore_path = ::File.join(node[:backup][:base_dir], "restore")

# Allow sudo access for backup user to run commands as postgres for database
# restoration
sudo 'restore' do
  user      node[:backup][:username]
  runas     'postgres'
  commands  ["ALL"]
  host      "ALL"
  nopasswd  true
end

directory restore_path do
  owner     "#{node[:backup][:username]}"
  group     "#{node[:backup][:group]}"
  mode      0755
  recursive true
end

# fetch_backup.sh helper script
fetch_backup_path = ::File.join(restore_path, "fetch_backup.sh")
template fetch_backup_path do
  source "fetch_backup.sh.erb"
  owner  "#{node[:backup][:username]}"
  group  "#{node[:backup][:group]}"
  mode   0755
  variables(
    :s3cfg    => node[:imos_backup][:s3][:config_file],
    :username => node[:imos_backup][:restore][:username]
  )
end

# Build restore script for node
restore_script_path = ::File.join(restore_path, "restore.sh")
Chef::Log.info("Restore script for node at '#{restore_script_path}'")
template restore_script_path do
  source "restore.sh.erb"
  owner  "root"
  group  "root"
  mode   0755
  variables(:fetch_backup => fetch_backup_path)
end
