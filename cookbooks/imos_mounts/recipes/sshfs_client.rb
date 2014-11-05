#
# Cookbook Name:: imos_mounts
# Recipe:: sshfs_client
#
# Copyright (C) 2014 IMOS
#
# All rights reserved - Do Not Redistribute
#

include_recipe "imos_mounts::sshfs_common"

package 'sshfs'

sshfs_user = node['imos_mounts']['sshfs']['user']
sshfs_ssh_key = Chef::EncryptedDataBagItem.load("users", sshfs_user)['ssh_priv_key']

file "/home/#{sshfs_user}/.ssh/id_rsa" do
  content sshfs_ssh_key
  user    sshfs_user
  mode    00400
end


# Mount all sshfs mounts
node['mounts']['mounts'].each do |mount|
  # Skip sshfs mounts here, we need the user created first
  next if mount['fstype'] != 'fuse.sshfs'

  # Make sure the mount point exists.
  directory mount['mount_point'] do
    recursive true
  end

  options = mount['options'] || "ro"
  options += "," + node['imos_mounts']['sshfs']['options']

  mount mount['mount_point'] do
    device  mount['device']
    fstype  mount['fstype']  || node['mounts']['fstype']
    options options
    action  [:mount, :enable]
  end

end if node['mounts'] && node['mounts']['mounts']
