#
# Cookbook Name:: jenkins
# Recipe:: node_common
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Install dependencies common to both master and slave nodes.
#

include_recipe "ruby_build"

# Set up ruby version and gems required for various jobs.
node.set['rbenv']['user_installs'] = [
  {
    'user'   => node['imos_jenkins']['user'],
    'rubies' => [ node['imos_jenkins']['ruby']['version'] ],
    'global' => node['imos_jenkins']['ruby']['version'],
    'gems'   => {
      node['imos_jenkins']['ruby']['version'] => node['imos_jenkins']['ruby']['gems']
    }
  }
]

include_recipe "rbenv::user"

rbenv_rehash "rehashing" do
  user user node['imos_jenkins']['user']
end
