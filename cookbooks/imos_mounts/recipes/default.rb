#
# Cookbook Name:: imos_mounts
# Recipe:: default
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#

# Most mounts would require the nfs package
package 'nfs-common'

# Fix for https://github.com/atomic-penguin/cookbook-nfs/issues/58
node.set['nfs']['service_provider']['server'] = Chef::Provider::Service::Init::Debian

node['mounts']['mounts'].each do |mount|
  # Skip sshfs mounts here, we need the user created first
  next if mount['fstype'] == 'fuse.sshfs'

  # Make sure the mount point exists.
  directory mount['mount_point'] do
    recursive true
  end

  mount mount['mount_point'] do
    device  mount['device']
    fstype  mount['fstype']  || node['mounts']['fstype']
    options mount['options'] || node['mounts']['options']
    action  [:mount, :enable]
  end

end if node['mounts'] && node['mounts']['mounts']
