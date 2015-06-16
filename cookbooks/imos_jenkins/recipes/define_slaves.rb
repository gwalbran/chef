#
# Cookbook Name:: jenkins
# Recipe:: define_slaves
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Recipe to define all slaves on a master
#

slave_nodes = search(:node, "fqdn:*").select {|n| n['run_list'].include?('recipe[imos_jenkins::slave]')}

slave_nodes.each do |n|
  slave_hostname = n['fqdn'].downcase

  Chef::Log.info("Configuring Jenkins slave '#{slave_hostname}'")

  remote_fs = n['imos_jenkins']['slave']['remote_fs'] or node['imos_jenkins']['slave']['remote_fs']
  executors = n['imos_jenkins']['slave']['executors'] or node['imos_jenkins']['slave']['executors']
  labels = n['imos_jenkins']['slave']['labels'] or node['imos_jenkins']['slave']['labels']

  jenkins_slave slave_hostname do
    remote_fs   remote_fs
    executors   executors.to_i
    labels      labels
    environment Chef::Recipe::JenkinsHelper.global_environment
  end
end
