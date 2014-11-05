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

# Override the original cookbook with our new template
begin
  r = resources(:template => node['squid']['config_file'])
  r.cookbook "imos_squid"
  r.variables[:refresh_patterns] = refresh_patterns
  r.variables[:custom_config]    = node['squid']['custom_config']
rescue Chef::Exceptions::ResourceNotFound
  Chef::Log.warn "imos_squid could not find template to override!"
end
