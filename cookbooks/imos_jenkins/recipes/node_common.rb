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
include_recipe "imos_core::jq"
include_recipe "imos_core::nco"
include_recipe "imos_core::xml_tools"
include_recipe "imos_devel::nco_devel"
include_recipe "imos_devel::chef_dk"
include_recipe "imos_devel::compliance_checker"
include_recipe "imos_devel::talend"
include_recipe "imos_devel::vagrant"
include_recipe "imos_po::packages"
include_recipe "imos_po::netcdf_checker"

include_recipe "imos_postgresql::official_postgresql"
include_recipe "git"
include_recipe "packer"

jenkins_user_data_bag = Chef::EncryptedDataBagItem.load("users", node['imos_jenkins']['user'])

node['imos_jenkins']['node_common']['packages'].each do |pkg|
  package pkg
end

# S3 configuration
s3cmd_config node['imos_jenkins']['s3cmd']['config_file'] do
  owner      node['imos_jenkins']['user']
  access_key jenkins_user_data_bag['access_key_id']
  secret_key jenkins_user_data_bag['secret_access_key']
end

node['imos_jenkins']['node_common']['python_packages'].each do |pkg|
  python_package pkg
end

cookbook_file "/usr/local/bin/s3redirect.py" do
  source "s3redirect.py"
  owner "root"
  group "root"
  mode 00755
end
