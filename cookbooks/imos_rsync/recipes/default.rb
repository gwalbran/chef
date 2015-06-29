#
# Cookbook Name:: imos_rsync
# Recipe:: default
#
# Copyright 2013, IMOS
#

# Include upstream rsync recipes
include_recipe "rsync"
include_recipe "rsync::server"

rsyncd_secrets_path = "/etc/rsyncd_secrets"

# Collect all defined rsync users
rsync_users = []
node['imos_rsync']['users'].each do |data_bag_name|
  data_bag = Chef::EncryptedDataBagItem.load('rsync_users', data_bag_name)
  rsync_users << {
    :username => data_bag['username'],
    :password => data_bag['password']
  }

  imos_po_incoming_email data_bag['username'] do
    email data_bag['email']
  end if data_bag['email']
end

template rsyncd_secrets_path do
  source   "rsyncd_secrets.erb"
  owner    "root"
  group    "root"
  mode     00600
  notifies :reload, "service[#{node['rsyncd']['service']}]"
  variables(:rsync_users => rsync_users)
end

# Create logging directory
directory node['imos_rsync']['log_dir'] do
  owner     "root"
  group     "root"
  mode      00755
  recursive true
end

# Define all the shares
node['imos_rsync']['serve'].each do |data_bag_name|
  data_bag = Chef::EncryptedDataBagItem.load('rsync_serve', data_bag_name)

  rsync_serve data_bag['id'] do
    path             data_bag['path']
    comment          "#{data_bag['id']}"
    secrets_file     rsyncd_secrets_path
    auth_users       data_bag['auth_users'].join(" ")
    incoming_chmod   "Dug+rwx,Fug+rw"
    use_chroot       false
    munge_symlinks   false
    read_only        data_bag['read_only']
    list             true
    uid              node['imos_rsync']['uid']
    gid              node['imos_rsync']['gid']
    hosts_allow      data_bag['hosts_allow'].join(", ")
    hosts_deny       "0.0.0.0/0"
    max_connections  node['imos_rsync']['max_connections']
    transfer_logging true
    log_file         ::File.join(node['imos_rsync']['log_dir'], "rsync_#{data_bag['id']}.log")
  end
end

# Rotate logs, since log_dir might be different
logrotate_app "rsyncd"  do
  cookbook   "logrotate"
  rotate     node['logrotate']['global']['rotate']
  path       ::File.join(node['imos_rsync']['log_dir'], "*.log")
  frequency  'weekly'
end
