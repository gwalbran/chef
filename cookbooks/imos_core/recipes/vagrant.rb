#
# Cookbook Name:: imos_core
# Recipe:: vagrant
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

node.set['vagrant'] = true
Chef::Config[:vagrant] = true

# Allow sudo for vagrant user
sudo 'vagrant' do
  user     "vagrant"
  runas    "ALL"
  commands ["ALL"]
  host     "ALL"
  nopasswd true
end
