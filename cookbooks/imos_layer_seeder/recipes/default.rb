#
# Cookbook Name:: imos_layer_seeder
# Recipe:: default
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#

# Ruby deps
ruby_pkg = 'ruby'
if node[:lsb]['codename'].include?("precise")
   ruby_pkg = 'ruby1.9.1'
end
package     ruby_pkg
package     'ruby-nokogiri'
gem_package 'trollop'

# # Download geoserver_seeder.rb from utilities repo
%w{ geoserver_seeder.rb geonetwork_connector.rb layer_seeder.rb}.each do |file|
  remote_file "/usr/local/bin/#{file}" do
    source "#{node['imos_layer_seeder']['base_url']}/#{file}"
    mode 00755
  end
end

template '/usr/local/bin/geowebcache.rb' do
  source 'geowebcache.rb.erb'
  owner 'root'
  group 'root'
  mode '0755'
end

# Extract parameters from node
geonetwork_url = node['imos_layer_seeder']['geonetwork']
start_zoom     = node['imos_layer_seeder']['start_zoom']
end_zoom       = node['imos_layer_seeder']['end_zoom']
type           = node['imos_layer_seeder']['type']

log_dir        = node['imos_layer_seeder']['log_dir']

seeding_cmd    = "timeout #{node['imos_layer_seeder']['duration']} /usr/local/bin/geoserver_seeder.rb \
-u #{geonetwork_url} \
-s #{start_zoom} \
-e #{end_zoom} \
-T #{type} > #{log_dir}/layer_seeder.log 2>&1"


cron "layer_seeder" do
  minute    node['imos_layer_seeder']['minute']
  hour      node['imos_layer_seeder']['hour']
  day       node['imos_layer_seeder']['day']
  month     node['imos_layer_seeder']['month']
  weekday   node['imos_layer_seeder']['weekday']

  # Escape the '%' character in cronjobs
  command   seeding_cmd.gsub('%', '\%')
  user      'root'
end
