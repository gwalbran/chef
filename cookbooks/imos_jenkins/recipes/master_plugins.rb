#
# Cookbook Name:: imos_jenkins
# Recipe:: master_plugins
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Recipe to install plugins on a jenkins master node.

include_recipe "imos_jenkins::master_auth"

node["imos_jenkins"]["plugins"].each do |plugin_name|
  jenkins_plugin plugin_name do
    notifies :restart, "service[jenkins]", :delayed
  end
end
