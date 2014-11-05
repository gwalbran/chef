#
# Author:: Joshua Sierles <joshua@37signals.com>
# Author:: Joshua Timberman <joshua@opscode.com>
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Author:: Seth Chisamore <schisamo@opscode.com>
# Cookbook Name:: nagios
# Recipe:: client
#
# Copyright 2009, 37signals
# Copyright 2009-2011, Opscode, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'socket'

# determine hosts that NRPE will allow monitoring from
nagios_servers = []

# Search for nodes with 'monitoring' role
monitoring_nodes = []
if Chef::Config[:solo]
  # No multi_environment_monitoring for chef-solo please :)
  # Yet again we can't search on chef-solo, so use this method to find nagios
  # monitoring nodes!
  monitoring_nodes = search(:node, "fqdn:*").select {|n| n['run_list'].include?("role[#{node['nagios']['server_role']}]") }
else
  if node['nagios']['multi_environment_monitoring']
    monitoring_nodes = search(:node, "role:#{node['nagios']['server_role']}")
  else
    monitoring_nodes = search(:node, "role:#{node['nagios']['server_role']} AND chef_environment:#{node.chef_environment}")
  end
end

# Get in all the nagios monitoring nodes
monitoring_nodes.each do |n|
  if n['network'] && n['network']['public_ipv4']
    nagios_servers << n['network']['public_ipv4']
  else
    Chef::Application.fatal!("Node '#{n['fqdn']}' does not have a network/public_ipv4 address!")
  end
end

# on the first run, search isn't available, so if you're the nagios server, go
# ahead and put your own IP address in the NRPE config (unless it's already there).
if node.run_list.roles.include?(node['nagios']['server_role'])
  unless nagios_servers.include?(node['ipaddress'])
    nagios_servers << node['ipaddress']
  end
end

include_recipe "nagios::client_#{node['nagios']['client']['install_method']}"

directory "#{node['nagios']['nrpe']['conf_dir']}/nrpe.d" do
  owner node['nagios']['user']
  group node['nagios']['group']
  mode 00755
end

# allowed_hosts will deal with all sort of weird firewalling and NAT issues, so
# it might contain a few more things on top of nagios_servers
allowed_hosts = nagios_servers + node['nagios']['allowed_hosts']

if node['vagrant']
  allowed_hosts.push('127.0.0.1')
end

template "#{node['nagios']['nrpe']['conf_dir']}/nrpe.cfg" do
  source "nrpe.cfg.erb"
  owner node['nagios']['user']
  group node['nagios']['group']
  mode 00644
  variables(
    :allowed_hosts => allowed_hosts,
    :nrpe_directory => "#{node['nagios']['nrpe']['conf_dir']}/nrpe.d"
  )
  notifies :restart, "service[#{node['nagios']['nrpe']['service_name']}]"
end

service node['nagios']['nrpe']['service_name'] do
  action [:start, :enable]
  supports :restart => true, :reload => true, :status => true
end

# Mock nsca config for vagrant machines, so it doesn't update production nagios
# servers
if node['vagrant']
  node.set['nagios']['nsca']['send_nsca'] = "/bin/true"
end

# In case there are no nagios servers - push the default value
# A way to solve the attributes of the nodes are being wiped on the chef
# server after a node definition update
if !nagios_servers.any?
  Chef::Application.fatal!("No nagios servers could be probed!!")
end

# Deploy broadcast_nsca, which will send NSCA to all registered servers
template "#{node['nagios']['nsca']['broadcast_nsca']}" do
  source "broadcast_nsca.erb"
  owner node['nagios']['user']
  group node['nagios']['group']
  mode 00755
  variables(:nagios_servers => nagios_servers)
end
