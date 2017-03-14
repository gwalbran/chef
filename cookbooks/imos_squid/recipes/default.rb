#
# Cookbook Name:: imos_squid
# Recipe:: default
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#

include_recipe "squid"

# Make sure directories exist
[ node['squid']['log_dir'], node['squid']['cache_dir'] ].each do |dir|
  directory dir do
    owner node['squid']['user']
    group node['squid']['group']
    mode 0755
    recursive true
  end
end

# Rotate logs, since log_dir might be different
logrotate_app "squid3"  do
  cookbook   "logrotate"
  rotate     node['logrotate']['global']['rotate']
  path       ::File.join(node['squid']['log_dir'], "*.log")
  frequency  'daily'
  options    [ "compress", "delaycompress", "missingok", "nocreate", "sharedscripts" ]
  postrotate "test ! -e /var/run/squid3.pid || /usr/sbin/squid3 -k rotate"
end

# Load refresh patterns
refresh_patterns = []
if node['squid'] && node['squid']['refresh_patterns']
  node['squid']['refresh_patterns'].each do |refresh_pattern|
    refresh_patterns << refresh_pattern
  end
end

# Refresh patterns from web apps
if node['webapps'] && node['webapps']['instances']
  node['webapps']['instances'].each do |webapp_instance|
    tomcat_instance_port = webapp_instance['port']

    webapp_instance['apps'].each do |app|
      app_name = app['name']
      # Prepend this to every refresh pattern regex line
      refresh_pattern_prefix = "http://localhost:#{tomcat_instance_port}/#{app_name}/"

      if app['refresh_patterns']
        app['refresh_patterns'].each do |refresh_pattern|
          # Copy object because we're not allowed to modify it
          refresh_pattern_for_webapp = refresh_pattern.dup
          refresh_pattern_for_webapp['regex'] = refresh_pattern_prefix + refresh_pattern_for_webapp['regex']
          refresh_patterns << refresh_pattern_for_webapp
        end
      end
    end

  end
end

# squid config include dir
# will only create directory if config_include_dir attribute is not nil
directory 'squid_config_include_dir' do
  path node['squid']['config_include_dir']
  action :create
  recursive true
  owner 'root'
  mode '755'
  only_if defined?(node['squid']['config_include_dir']).nil?
end

# custom squid config
custom_config_file = ::File.join(node['squid']['config_include_dir'], 'imos-custom.conf')
template custom_config_file do
  source 'imos-custom.conf.erb'
  notifies :reload, "service[#{node['squid']['service_name']}]"
  mode '644'
  variables(
    lazy do
      {
        refresh_patterns: refresh_patterns
      }
    end
  )
end
