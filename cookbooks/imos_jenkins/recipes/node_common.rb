#
# Cookbook Name:: jenkins
# Recipe:: node_common
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Install dependencies common to both master and slave nodes.
#
node.set['build_essential']['compiletime'] = true

# Jenkins needs to compile and build a lot of things during node provision time
include_recipe 'build-essential'

include_recipe "imos_java"
include_recipe "imos_core::xml_tools"
include_recipe "imos_devel::nco_devel"
include_recipe "imos_devel::chef_dk"
include_recipe "imos_devel::talend"
include_recipe "imos_devel::vagrant"

include_recipe 'imos_postgresql::sharpie_postgresql_9_1'
include_recipe 'git'
include_recipe 'packer'

package "firefox"
package "shunit2"
package "zip"

jenkins_user_data_bag = Chef::EncryptedDataBagItem.load("users", node['imos_jenkins']['user'])

# Copy the private key
file "/home/jenkins/.ssh/id_rsa" do
  content jenkins_user_data_bag['ssh_priv_key']
  user    node['imos_jenkins']['user']
  group   node['imos_jenkins']['group']
  mode    00400
end

# Needed so that ssh logins to various places use the correct key (e.g. github).
# Also, for nectar VMs, we want to accept news hosts automatically.
template "/home/jenkins/.ssh/config" do
  source "ssh_config.erb"
  user   node['imos_jenkins']['user']
  group  node['imos_jenkins']['group']
  mode   00644
  variables({
    :user => 'jenkins'
  })
end

# S3 configuration
s3cmd_config node['imos_jenkins']['s3cmd']['config_file'] do
  owner      node['imos_jenkins']['user']
  access_key jenkins_user_data_bag['access_key_id']
  secret_key jenkins_user_data_bag['secret_access_key']
end
