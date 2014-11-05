#
# Cookbook Name:: imos_dns
# Recipe:: etc_hosts
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

# A quick recipe to configure /etc/hosts
node['imos_dns']['etc_hosts'].each do |ip_addr, names|
  hostsfile_entry "#{ip_addr} #{names}" do
    ip_address ip_addr
    hostname   names
    action :create
  end
end
