#
# Cookbook Name:: imos_mounts
# Definition:: opendap
#
# Copyright 2012, IMOS
#
# All rights reserved - Do Not Redistribute
#

# mounts opendap (read only is the default)
define :opendap do
  mount_index      = params[:index] || 1
  mount_parameters = params[:mount_parameters] || "_netdev,defaults,noatime,hard,intr,ro"
  mount_point      = "/mnt/opendap/#{mount_index}"

  # Create the /mnt/imos-tX directory
  directory mount_point do
    recursive true
  end

  mount mount_point do
    device  "#{node['mounts']['opendap_nfs_server']}:/#{mount_point}"
    fstype  "nfs"
    options mount_parameters
    action  [:mount, :enable]
  end
end

