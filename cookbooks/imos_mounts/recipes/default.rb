#
# Cookbook Name:: imos_mounts
# Recipe:: default
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#

# Remove mlocate if there are foreign mounts, just because it'll start indexing
# the whole mount point. Especially not good if there's a s3fs mount
package 'mlocate' do
  action :remove
end

# Most mounts would require the nfs package
package 'nfs-common'

# Fix for https://github.com/atomic-penguin/cookbook-nfs/issues/58
node.set['nfs']['service_provider']['server'] = Chef::Provider::Service::Init::Debian

node['mounts']['mounts'].each do |mount|
  # Skip sshfs mounts here, we need the user created first
  next if MountHelper.is_sshfs(mount)

  actions = [:mount, :enable]
  MountHelper.is_s3fs(mount) and actions = [:enable]

  # Make sure the mount point exists.
  directory mount['mount_point'] do
    recursive true
  end

  mount mount['mount_point'] do
    device  mount['device']
    fstype  mount['fstype']  || node['mounts']['fstype']
    options mount['options'] || node['mounts']['options']
    action  actions
  end

end if node['mounts'] && node['mounts']['mounts']
