#
# Cookbook Name:: imos_logstash
# Recipe:: ssl_certs
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#
directory File.join(node['logstash']['instance']['default']['basedir'], 'ssl') do
  owner    node['logstash']['instance']['default']['user']
  group    node['logstash']['instance']['default']['group']
end

file node['imos_logstash']['indexer']['lumberjack']['ssl_key_path'] do
  owner    node['logstash']['instance']['default']['user']
  group    node['logstash']['instance']['default']['group']
  content  Chef::EncryptedDataBagItem.load('ssl', 'logstash')['key']
  mode     0640
  action   :create
end

file node['imos_logstash']['indexer']['lumberjack']['ssl_cert_path'] do
  owner    node['logstash']['instance']['default']['user']
  group    node['logstash']['instance']['default']['group']
  content  Chef::EncryptedDataBagItem.load('ssl', 'logstash')['cert']
  mode     0644
  action   :create
end
