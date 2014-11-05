#
# Cookbook Name:: imos_logstash
# Recipe:: webapp_agent
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#

name = 'agent'

logstash_config name do
  templates ({ "input_webapp" => 'config/input_webapp.conf.erb' })
  templates_cookbook 'imos_logstash'
  variables(
    instances: node['webapps']['instances']
  )
  notifies :restart, "logstash_service[#{name}]", :delayed
end
