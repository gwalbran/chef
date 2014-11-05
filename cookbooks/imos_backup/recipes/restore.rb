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

# id_rsa for pulling backups
restore_id_rsa_path = ::File.join(restore_path, "id_rsa")
restore_ssh_key = Chef::EncryptedDataBagItem.load("users", node[:imos_backup][:restore][:username])['ssh_priv_key']
file restore_id_rsa_path do
  content restore_ssh_key
  owner   "#{node[:backup][:username]}"
  group   "#{node[:backup][:group]}"
  mode    0400
end

# Add all backup server host keys to known hosts
known_hosts_tuples = []
search(:node, "fqdn:*").each do |n|
  if n['run_list'].include?("recipe[imos_backup::server]")
    Chef::Log.info("Adding backup server '#{n['fqdn']}' to known hosts")
    known_hosts_tuples.push([
      n['network']['public_ipv4'],
      node[:imos_backup][:restore][:from_host],
      n['keys']['ssh']['host_rsa_public']
    ])
  end
end

restore_known_hosts_path = ::File.join(restore_path, "known_hosts")
template restore_known_hosts_path do
  source "known_hosts.erb"
  owner  "#{node[:backup][:username]}"
  group  "#{node[:backup][:group]}"
  mode   0644
  variables(:items => known_hosts_tuples.sort!)
end

# fetch_backup.sh helper script
fetch_backup_path = ::File.join(restore_path, "fetch_backup.sh")
template fetch_backup_path do
  source "fetch_backup.sh.erb"
  owner  "#{node[:backup][:username]}"
  group  "#{node[:backup][:group]}"
  mode   0755
  variables(
    :id_rsa      => restore_id_rsa_path,
    :known_hosts => restore_known_hosts_path,
    :username    => node[:imos_backup][:restore][:username]
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
