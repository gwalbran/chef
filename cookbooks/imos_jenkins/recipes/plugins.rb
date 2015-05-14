#
# Cookbook Name:: imos_jenkins
# Recipe:: plugins
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Recipe to install plugins on a jenkins master node.

node["imos_jenkins"]["plugins"].each do |plugin_name|
  jenkins_plugin plugin_name
end
