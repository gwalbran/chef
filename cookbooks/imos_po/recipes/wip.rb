#
# Cookbook Name:: imos_po
# Recipe:: wip
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#
# Sets up a server to allow project officers to do data manipulation

include_recipe "imos_mounts"

# Give them a data directory to do things on
directory node['imos_po']['wip_dir'] do
  mode      01777
  recursive true
end

