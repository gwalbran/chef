#
# Cookbook Name:: imos_mounts
# Recipe:: nfs_server
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#

include_recipe "nfs::server"

node['mounts']['nfs_exports'].each do |nfs_export|
  nfs_export  nfs_export['nfs_export'] do
    network   nfs_export['network']
    writeable nfs_export['writeable']
    sync      nfs_export['sync']
    options   nfs_export['options'].split(' ')
  end
end
