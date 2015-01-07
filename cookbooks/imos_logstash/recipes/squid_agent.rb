#
# Cookbook Name:: imos_logstash
# Recipe:: squid_agent
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#

name = 'agent'

# Logstash needs to be able to read the squid log.
group node['squid']['group'] do
  append true
  members [node['logstash']['instance_default']['user']]
  action :modify
end

logstash_config name do
  templates ({ "input_squid" => 'config/input_squid.conf.erb' })
  templates_cookbook 'imos_logstash'
  notifies :restart, "logstash_service[#{name}]", :delayed
end
