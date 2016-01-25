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

group node['imos_rsync']['group'] do
  members node['imos_rsync']['user']
  append  true
end

# Collect all defined rsync users
if node['imos_rsync'] && node['imos_rsync']['chroot_users']
  node['imos_rsync']['chroot_users'].each do |data_bag_name|
    data_bag = Chef::EncryptedDataBagItem.load('rsync_chroot_users', data_bag_name)
    directory = Chef::Recipe::RsyncHelper.amend_path(data_bag['directory'], node['imos_rsync']['incoming_dir'])

    if node['imos_rsync']['create_directories']
      directory directory do
        recursive true
        owner     node['imos_rsync']['user']
        group     node['imos_rsync']['group']
        mode      00775
      end
    end

    rsync_chroot_user "rsync_chroot_#{data_bag['id']}" do
      user      data_bag['user'] || node['imos_rsync']['user']
      key       data_bag['ssh_key']
      directory directory
      comment   data_bag['email'] or data_bag['id']
    end
  end
end
