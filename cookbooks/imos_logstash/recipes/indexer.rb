#
# Cookbook Name:: imos_logstash
# Recipe:: indexer
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#

name = 'server'

# Merge attributes defined in node definitions etc
logstash_instance_attributes = {}
logstash_instance_attributes['join_groups'] = ['ssl-cert']
logstash_instance_attributes.merge!(node['logstash']['instance'][name])
node.set['logstash']['instance'][name] = logstash_instance_attributes

Chef::Application.fatal!("attribute hash node['logstash']['instance']['#{name}'] must exist.") if node['logstash']['instance'][name].nil?

logstash_instance name do
  action :create
end

logstash_service name do
  action [:enable]
end

logstash_config name do
  templates ({ 'output_elasticsearch' => 'config/output_elasticsearch.conf.erb' })
  variables(
    elasticsearch_embedded: true
  )
  notifies :restart, "logstash_service[#{name}]", :delayed
end

include_recipe "imos_logstash::ssl_certs"

logstash_config name do
  templates ({ 'input_lumberjack' => 'config/input_lumberjack.conf.erb' })
  templates_cookbook 'imos_logstash'
  notifies :restart, "logstash_service[#{name}]", :delayed
end

logstash_plugins 'contrib' do
  instance name
  action [:create]
end

logstash_pattern name do
  action [:create]
end

logstash_service name do
  action      [:start]
end

logstash_curator 'server' do
  action [:create]
end
