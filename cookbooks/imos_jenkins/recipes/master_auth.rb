#
# Cookbook Name:: imos_jenkins
# Recipe:: master_auth
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Recipe to authorise on master.
#
# Note: that this step will need to be done manually and in advance of running this recipe on our
# existing jenkins instance - as authentication is already enabled there.

chef_user_data_bag = Chef::EncryptedDataBagItem.load('users', 'chef')

# Set the private key on the Jenkins executor
ruby_block 'set private key' do
  block { node.set['jenkins']['executor']['private_key'] = chef_user_data_bag['ssh_private_key'] }
end

# Create the Jenkins user with the public key
jenkins_user 'chef' do
  full_name   chef_user_data_bag['full_name']
  email       chef_user_data_bag['email']
  public_keys [chef_user_data_bag['ssh_public_key']]
end
