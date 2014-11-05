#
# Cookbook Name:: imos_logstash
# Recipe:: jenkins_agent
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#

name = 'agent'

logstash_config name do
  templates ({ 'input_jenkins' => 'config/input_jenkins.conf.erb' })
  templates_cookbook 'imos_logstash'
  notifies :restart, "logstash_service[#{name}]", :delayed
end
