#
# Cookbook Name:: imos_jenkins
# Recipe:: plugins
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Recipe to install plugins on a jenkins master node.

plugins_dir = File.join(node['jenkins']['master']['home'], 'plugins')

directory plugins_dir do
  mode   '0755'
  owner  node['jenkins']['master']['user']
  group  node['jenkins']['master']['group']
end

node["imos_jenkins"]["plugins"].each do |plugin_name|
  file File.join(plugins_dir, "#{plugin_name}.jpi.pinned") do
    mode   '0644'
    owner  node['jenkins']['master']['user']
    group  node['jenkins']['master']['group']
    action :touch
  end

  # It's necessary to restart immediately, since downstream recipe code relies on plugins installed here
  # (otherwise we get ClassNotFoundExceptions and the like).
  jenkins_plugin plugin_name do
    notifies :restart, 'service[jenkins]', :immediately
  end
end
