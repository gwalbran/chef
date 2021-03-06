#
# Cookbook Name:: imos_core
# Recipe:: chef_solo
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'apt'

# Include those recipes if running under chef-solo
if Chef::Config[:solo]
  include_recipe "chef-solo-search"
end

# In dev mode, there is no need to cleanup as the directories are shared with
# the host
if Chef::Config[:solo] && ! Chef::Config[:dev]
  # If we're with chef solo, we must clean credentials after the run
  remote_directory node['chef_handler']['handler_path'] do
    source    'handlers'
    owner     node['chef_handler']['root_user']
    group     node['chef_handler']['root_group']
    mode      0755
    recursive true
    action    :create
  end

  # Chef cleaner handler, cleans cookbooks and data bags on remote machine
  chef_handler "Imos::CleanerHandler" do
  source "#{node['chef_handler']['handler_path']}/cleaner_handler"
    supports :report => true, :exception => true
    action   :enable
  end
end
