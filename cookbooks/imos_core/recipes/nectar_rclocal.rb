#
# Cookbook Name:: imos_core
# Recipe:: nectar_rclocal
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

cookbook_file '/etc/rc.local' do
  source 'rc.local-nectar'
  mode '0755'
  only_if { node.run_list?('role[nectar]') }
end
