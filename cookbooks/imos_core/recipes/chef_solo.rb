#
# Cookbook Name:: imos_core
# Recipe:: chef_solo
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

# Include those recipes if running under chef-solo
if Chef::Config[:solo]
  include_recipe "chef-solo-search"
end
