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

node.set['imos_devel']['vagrant']['plugins'] = [
  {
    'name' => 'vagrant-berkshelf',
    'user' => node['imos_jenkins']['user'],
    'home' => '/home/jenkins',
    'version' => '2.0.1'
  },
  {
    'name' => 'vagrant-cachier',
    'user' => node['imos_jenkins']['user'],
    'home' => '/home/jenkins'
  },
  {
    'name' => 'vagrant-vbguest',
    'user' => node['imos_jenkins']['user'],
    'home' => '/home/jenkins'
  }
]

include_recipe "imos_devel::vagrant"
include_recipe "imos_devel::virtualbox"

include_recipe "imos_jenkins::ruby"

include_recipe 'imos_postgresql::sharpie_postgresql_9_1'
include_recipe 'grails'
include_recipe 'git'
include_recipe 'xvfb'
include_recipe 'packer'

package "zip"
package "shunit2"

# Copy the private key
jenkins_ssh_key = Chef::EncryptedDataBagItem.load("users", node['imos_jenkins']['user'])['ssh_priv_key']
file "/home/jenkins/.ssh/id_rsa" do
  content jenkins_ssh_key
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

# This file is used to check that the portal is running (with correct version).
directory "/home/jenkins/scripts" do
  user  node['imos_jenkins']['user']
  group node['imos_jenkins']['group']
end

cookbook_file "/home/jenkins/scripts/check_running.sh" do
  source "check_running.sh"
  mode   00500
  user   node['imos_jenkins']['user']
  group  node['imos_jenkins']['group']
end

# Maven setting for jenkins user.
directory "/home/jenkins/.m2" do
  user  node['imos_jenkins']['user']
  group node['imos_jenkins']['group']
end

cookbook_file "/home/jenkins/.m2/settings.xml" do
  source "settings.xml"
  mode   00644
  user   node['imos_jenkins']['user']
  group  node['imos_jenkins']['group']
end
