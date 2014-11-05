#
# Cookbook Name:: imos_logstash
# Recipe:: kibana
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#

node.set['kibana']['webserver'] = 'apache'
node.set['kibana']['apache']['template_cookbook'] = 'imos_logstash'

webserver = node['kibana']['webserver']
kibana_user = node[webserver]['user']

kibana_install 'kibana' do
  user kibana_user
  group kibana_user
  install_dir node['kibana']['install_dir']
  install_type node['kibana']['install_type']
  action :create
end

template File.join(node['kibana']['install_dir'], 'current/config.js') do
  source node['kibana']['config_template']
  cookbook node['kibana']['config_cookbook']
  mode '0750'
  user kibana_user
end

link File.join(node['kibana']['install_dir'], '/current/app/dashboards/default.json') do
  to 'logstash.json'
  only_if { !File.symlink?("#{node['kibana']['install_dir']}/current/app/dashboards/default.json") }
end

kibana_web 'kibana' do
  type node['kibana']['webserver']
  template_cookbook 'imos_logstash'
  docroot "#{node['kibana']['install_dir']}/current"
  es_server node['kibana']['es_server']
  server_name node['imos_logstash']['kibana']['host']
  listen_address '*'
  listen_port '443'
  not_if { node['kibana']['webserver'].empty? }
end

sysadmins = Users.find_users_in_groups(node['imos_logstash']['kibana']['user_groups'])

template File.join(node['kibana']['install_dir'], 'htpasswd.users') do
  source "htpasswd.users.erb"
  owner node["apache"]["group"]
  mode 00640
  variables({
    :sysadmins => sysadmins
  })
end
