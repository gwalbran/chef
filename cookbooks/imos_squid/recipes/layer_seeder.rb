#
# Cookbook Name:: imos_squid
# Recipe:: layer_seeder
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#

# Ruby deps
package     'ruby1.9.1'
package     'ruby-nokogiri'
gem_package 'trollop'

# Download geoserver_seeder.rb from utilities repo
%w{ geoserver_seeder.rb }.each do |file|
  remote_file "/usr/local/bin/#{file}" do
    source "#{node['imos_squid']['layer_seeder']['base_url']}/#{file}"
    mode 00755
  end
end

# Extract parameters from node
geonetwork_url = node['imos_squid']['layer_seeder']['geonetwork']
geoserver_url  = node['imos_squid']['layer_seeder']['geoserver']
geoserver_port = node['imos_squid']['layer_seeder']['geoserver_port']
start_zoom     = node['imos_squid']['layer_seeder']['start_zoom']
end_zoom       = node['imos_squid']['layer_seeder']['end_zoom']
threads        = node['imos_squid']['layer_seeder']['threads']
tile_size      = node['imos_squid']['layer_seeder']['tile_size']
gutter_size    = node['imos_squid']['layer_seeder']['gutter_size']
url_format     = node['imos_squid']['layer_seeder']['url_format']
log_dir        = node['squid']['log_dir']

seeding_cmd    = "timeout #{node['imos_squid']['layer_seeder']['duration']} /usr/local/bin/geoserver_seeder.rb \
-P \
-u #{geonetwork_url} \
-g #{geoserver_url} \
-p #{geoserver_port} \
-s #{start_zoom} \
-e #{end_zoom} \
-t #{threads} \
-T #{tile_size} \
-G #{gutter_size} \
-U '#{url_format}' > #{log_dir}/layer_seeder.log 2>&1"

cron "layer_seeder" do
  minute    node['imos_squid']['layer_seeder']['minute']
  hour      node['imos_squid']['layer_seeder']['hour']
  day       node['imos_squid']['layer_seeder']['day']
  month     node['imos_squid']['layer_seeder']['month']
  weekday   node['imos_squid']['layer_seeder']['weekday']

  # Escape the '%' character in cronjobs
  command   seeding_cmd.gsub('%', '\%')
  user      'root'
end
