#
# Cookbook Name:: imos_core
# Recipe:: sysctl
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#

# Set net.ipv4.tcp_timestamps=0, required to pass UTAS security scans
sysctl 'net.ipv4.tcp_timestamps' do
  value '0'
end
