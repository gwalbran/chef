#
# Cookbook Name:: imos_rsync
# Recipe:: chroot
#
# Copyright 2013, IMOS
#

# Include upstream rsync_chroot recipe
include_recipe "rsync_chroot"

user node['imos_rsync']['user'] do
  supports :manage_home => true
  home     ::File.join("/home", node['imos_rsync']['user'])
  action   :create
end

# Collect all defined rsync users
if node['imos_rsync'] && node['imos_rsync']['chroot_users']
  node['imos_rsync']['chroot_users'].each do |data_bag_name|
    data_bag = Chef::EncryptedDataBagItem.load('rsync_chroot_users', data_bag_name)

    directory data_bag['directory'] do
      recursive true
      owner     node['imos_rsync']['user']
      mode      00755
    end

    rsync_chroot_user "rsync_chroot_#{data_bag['id']}" do
      user      data_bag['user'] || node['imos_rsync']['user']
      key       data_bag['ssh_key']
      directory data_bag['directory']
      comment   data_bag['email']
    end
  end
end
