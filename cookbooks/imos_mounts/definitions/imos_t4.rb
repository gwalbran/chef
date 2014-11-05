#
# Cookbook Name:: imos_mounts
# Definition:: imos_t4
#
# Copyright 2012, IMOS
#
# All rights reserved - Do Not Redistribute
#

# mounts imos_t4 (read only is the default)
define :imos_t4 do
  mount_parameters = params[:mount_parameters] || "_netdev,defaults,noatime,hard,intr,ro"
  mount_point      = "imos-t4"

  # Create the /mnt/imos-tX directory
  directory "/mnt/#{mount_point}" do
    recursive true
  end

  mount "/mnt/#{mount_point}" do
    device  "#{node['mounts']['nsp_nfs_server']}:/#{mount_point}"
    fstype  "nfs"
    options mount_parameters
    action  [:mount, :enable]
  end
end

