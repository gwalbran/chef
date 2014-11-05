#
# Cookbook Name:: imos_mounts
# Recipe:: opendap_rw
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#

opendap do
  mount_parameters "_netdev,defaults,noatime,hard,intr,rw"
end

