#
# Cookbook Name:: imos_logstash
# Recipe:: talend_agent
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#

if node['talend'] && node['talend']['jobs']

  name = 'agent'

  logstash_config name do
    templates ({ "input_talend" => 'config/input_talend.conf.erb' })
    templates_cookbook 'imos_logstash'
    notifies :restart, "logstash_service[#{name}]", :delayed
  end

end
