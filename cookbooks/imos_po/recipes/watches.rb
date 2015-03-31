#
# Cookbook Name:: imos_po
# Recipe:: watches
#
# Copyright (C) 2015 IMOS
#
# All rights reserved - Do Not Redistribute
#
# Setup watches defined by project officers in watch.d directory

include_recipe "rsyslog"

data_services_dir = node['imos_po']['data_services']['dir']
data_services_watch_dir = File.join(data_services_dir, "watch.d")
watch_exec_wrapper = node['imos_po']['watch_exec_wrapper']

template watch_exec_wrapper do
  source "watch-exec-wrapper.sh.erb"
  owner  'root'
  group  'root'
  mode   0755
  variables ({
    :env => node['imos_po']['data_services']['env'],
    :lib => node['imos_po']['data_services']['lib']
  })
end

if node['imos_po']['data_services']['watches']
  package 'incron'
  package 'lsof'

  template "/etc/incron.d/po" do
    source    "incron.d.erb"
    mode      00644
    owner     "root"
    group     "root"
    variables ({
      :watch_exec_wrapper      => watch_exec_wrapper,
      :data_services_env       => node['imos_po']['data_services']['env'],
      :data_services_dir       => data_services_dir,
      :data_services_watch_dir => data_services_watch_dir
    })
  end

  service "incron" do
    action [:start, :enable]
  end

end

log_dir  = ::File.join(node['imos_po']['data_services']['log_dir'])
log_file = ::File.join(log_dir, "process.log")

file ::File.join(node['rsyslog']['config_prefix'], "rsyslog.d", "60-project-officer-process.conf") do
  content  "#{node['imos_po']['watches']['syslog_facility']}.* #{log_file}
"
  owner    'root'
  group    'root'
  mode     '0644'
  notifies :restart, "service[#{node['rsyslog']['service_name']}]"
end

logrotate_app "project-officer-processing" do
  rotate     node['logrotate']['global']['rotate']
  path       log_file
  frequency  'daily'
  options    [ "compress", "delaycompress", "missingok", "nocreate", "sharedscripts" ]
end

logrotate_app "project-officer-processing-file-reports" do
  rotate     node['logrotate']['global']['rotate']
  path       ::File.join(log_dir, "*", "*.log")
  frequency  'daily'
  options    [ "compress", "delaycompress", "missingok", "nocreate", "sharedscripts" ]
end