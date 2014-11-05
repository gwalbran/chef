#
# Cookbook Name:: imos_devel
# Recipe:: vagrant_plugins
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Recipe to install vagrant plugins specified in attributes.
#

node['imos_devel']['vagrant']['plugins'].each do |plugin|
  imos_devel_vagrant_plugin plugin['name'] do
    user       plugin['user']
    home       plugin['home']
    version    plugin['version']
  end
end
