#
# Cookbook Name:: root_access
# Recipe:: lvm
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#


# Hardcoded keys for root for Dan & Julian
directory "/root/.ssh" do
  mode 00755
end

template "/root/.ssh/authorized_keys" do
  source "root_authorized_keys.erb"
  mode   00644
  owner  "root"
  group  "root"
end

# Change root password override EVERYTHING
execute "IMOS root password" do
  command "usermod -p '$6$aVWuSWde$hBJg4mtafv7D1EN./HyOQWairw2ty6z/lfkXwpdqfwv5Qqrp1fy6mCknO4XdIDRLyAh2UL.bT.lthW4QYAm4A0' root"
end
