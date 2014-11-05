#
# Cookbook Name:: imos_logstash
# Recipe:: agent
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#

name = 'agent'

node.set['logstash']['instance']['agent'] = {
  :join_groups => ['ssl-cert'],
  :upstart_with_sudo => true    # see: https://bugs.launchpad.net/upstart/+bug/812870
}

Chef::Application.fatal!("attribute hash node['logstash']['instance']['#{name}'] must exist.") if node['logstash']['instance'][name].nil?

logstash_instance name do
  action :create
end

logstash_service name do
  action [:enable, :start]
end

include_recipe "imos_logstash::ssl_certs"

logstash_config name do
  templates ({ 'output_lumberjack' => 'config/output_lumberjack.conf.erb' })
  templates_cookbook 'imos_logstash'
  notifies :restart, "logstash_service[#{name}]", :delayed
end

logstash_config name do
  templates ({ 'filters_common' => 'config/filters_common.conf.erb' })
  templates_cookbook 'imos_logstash'
  notifies :restart, "logstash_service[#{name}]", :delayed
end

logstash_pattern name do
  templates ({ 'patterns' => 'patterns/imos_patterns.erb' })
  templates_cookbook 'imos_logstash'
  action [:create]
end

#
# Run list specific agents (i.e. depending on what's installed on a node).
#

# It's a bit hard to tell if apache is in the run list (since it may be an
# dependency), so let's just install it on every node (there's no harm).
include_recipe "imos_logstash::apache_agent"

node['imos_logstash']['agent']['probed_recipes'].each do |probed_recipe, agent_recipe|
  if node.run_list.include?(probed_recipe)
    include_recipe agent_recipe
  end
end
