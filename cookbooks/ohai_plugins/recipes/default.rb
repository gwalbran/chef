#
# Cookbook Name:: ohai_plugins
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# Include some ohai attributes here
# Do not include them however if running with chef-solo!
if ! Chef::Config[:solo]
  cookbook_file "#{node['ohai']['plugin_path']}/public_ipv4.rb" do
    source "plugins/public_ipv4.rb"
    owner "root"
    group "root"
    mode 00755
  end

  include_recipe "ohai"
end
