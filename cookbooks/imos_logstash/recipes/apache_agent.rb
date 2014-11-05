#
# Cookbook Name:: imos_logstash
# Recipe:: apache_agent
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#

name = 'agent'

logstash_config 'agent' do
  templates ({ 'input_apache' => 'config/input_apache.conf.erb' })
  templates_cookbook 'imos_logstash'
  variables(
    path: File.join(node['apache']['log_dir'], '*-access.log')
  )
  notifies :restart, "logstash_service[#{name}]", :delayed
end
