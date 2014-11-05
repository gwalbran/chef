#
# Cookbook Name:: backup
# Recipe:: dir_sync
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#

include_recipe "imos_backup::ssh_config"

backup_user_homedir = Chef::EncryptedDataBagItem.load("users", node[:backup][:username])['home']
backup_ssh_private_key = ::File.join(backup_user_homedir, ".ssh", "id_rsa")

# Iterate on data bags and configure dir_sync
node[:imos_backup][:dir_sync][:data_bags].each do |data_bag_name|
  data_bag = data_bag_item('dir_sync', data_bag_name)

  log_file = ::File.join(node[:backup][:log_dir], "dir_sync_#{data_bag['id']}.log")

  command = "rsync #{data_bag['rsync_options']} -e \"ssh -i #{backup_ssh_private_key}\" " + \
    "#{node[:backup][:username]}@#{data_bag['src_path']} " + \
    "#{data_bag['dst_path']} " + \
    ">> #{log_file} 2>&1"

  if node['vagrant']
    Chef::Log.warn("MOCKED - not configuring dir_sync command '#{command}'")
  else
    cron "dir_sync_#{data_bag['id']}" do
      minute  data_bag['cron']['minute']
      hour    data_bag['cron']['hour']
      day     data_bag['cron']['day']
      month   data_bag['cron']['month']
      weekday data_bag['cron']['weekday']
      command command
      user    node[:backup][:username]
    end
  end
end
