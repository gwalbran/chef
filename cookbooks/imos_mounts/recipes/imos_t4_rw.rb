#
# Cookbook Name:: imos_mounts
# Recipe:: imos_t4_rw
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#

imos_t4 do
  mount_parameters "_netdev,defaults,noatime,hard,intr,rw"
end
