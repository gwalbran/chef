#
# Cookbook Name:: imos_core
# Recipe:: motd
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#

if(File.exists?("/etc/motd") and File.lstat("/etc/motd").symlink?)
  File.unlink("/etc/motd")
end

template "/etc/motd" do
  source "motd.erb"
  mode 00644
  owner "root"
  group "root"
end
