#
# Cookbook Name:: jenkins
# Recipe:: slave
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Recipe to configure a jenkins slave node.
#

include_recipe 'imos_jenkins::node_common'

package "daemon"

directory node['imos_jenkins']['slave']['directory'] do
  owner     node['imos_jenkins']['user']
  group     node['imos_jenkins']['user']
  mode      00755
  recursive true
end

# init.d service file
cookbook_file "/etc/init.d/jenkins-slave" do
  source "jenkins-slave.init"
  owner  "root"
  group  "root"
  mode   00755
end

# Configuration variables for init.d service
template "/etc/default/jenkins-slave" do
  source "jenkins-slave.erb"
  owner  "root"
  group  "root"
  mode   00755
end

# Start jenkins-slave service
service "jenkins-slave" do
  supports [:stop, :start, :restart]
  action   [:start, :enable]
end
