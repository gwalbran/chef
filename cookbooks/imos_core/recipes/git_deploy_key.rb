#
# Cookbook Name:: imos_core
# Recipe:: git_deploy_key
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

deploy_key = Chef::EncryptedDataBagItem.load("deploy_keys", "github")['ssh_priv_key']
git_ssh_wrapper "git" do
  owner        'root'
  group        'root'
  ssh_key_data deploy_key
end

# This is where the ssh wrapper will be
node.set['git_ssh_wrapper'] = File.join("/root", ".ssh", "wrappers", "git_deploy_wrapper.sh")
