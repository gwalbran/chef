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

# Allow anyone in 'projectofficer' group to sudo to user 'projectofficer'
sudo 'data_services_watches' do
  user     node['imos_po']['data_services']['user']
  runas    'root'
  commands [ "/bin/cat /etc/rsyncd.conf", "/bin/cat /var/log/vsftpd.log" ]
  host     "ALL"
  nopasswd true
end

template watch_exec_wrapper do
  source "watch-exec-wrapper.sh.erb"
  owner  'root'
  group  'root'
  mode   0755
  variables ({
    :env   => node['imos_po']['data_services']['env'],
    :user  => node['imos_po']['data_services']['user'],
    :group => node['imos_po']['data_services']['group']
  })
end

if node['imos_po']['data_services']['watches']
  include_recipe 'imos_core::incron'
  include_recipe 'rabbitmq'
  package 'lsof'

  template "/etc/incron.d/po" do
    source    "incron.d.erb"
    mode      00644
    owner     "root"
    group     "root"
    variables ({
      :watchlists         => Chef::Recipe::WatchJobs.get_watches(data_services_watch_dir),
      :watch_exec_wrapper => watch_exec_wrapper,
      :data_services_dir  => data_services_dir
    })
  end

  template "/etc/incron.d/po" do
    source    "incron.d.erb"
    variables ({
      :watchlists        => Chef::Recipe::WatchJobs.get_watches(data_services_watch_dir),
      :data_services_dir => data_services_dir
    })
  end

  service "incron" do
    action [:start, :enable]
  end


  # Celeryd configuration
  python_pip "celery"
  python_pip "boto"
  include_recipe "supervisor"

  celery_config = node['imos_po']['data_services']['celeryd']['config']

  directory node['imos_po']['data_services']['celeryd']['dir']
  template node['imos_po']['data_services']['celeryd']['tasks'] do
    source    "tasks.py.erb"
    variables ({
      :celery_config     => ::File.basename(celery_config),
      :watchlists        => Chef::Recipe::WatchJobs.get_watches(data_services_watch_dir),
      :data_services_dir => data_services_dir
    })
    notifies  :restart, "supervisor_service[celery_po]"
  end

  backend = node['imos_po']['data_services']['celeryd']['backend']
  password_data_bag = node['imos_po']['data_services']['celeryd']['password_data_bag']
  if Chef::Config[:dev] # TODO
    password_data_bag = nil
    backend = "rabbitmq"
  end

  template celery_config do
    source    "celeryconfig.py.erb"
    variables ({
      :password_data_bag => password_data_bag,
      :backend           => backend
    })
    notifies  :restart, "supervisor_service[celery_po]"
  end

  cookbook_file node['imos_po']['data_services']['celeryd']['queuer'] do
    cookbook "imos_po"
    source   "queuer.py"
    mode     00755
  end

  supervisor_service "celery_po" do
    action    :enable
    autostart true
    command   "celeryd --config=#{celery_config} -A tasks -c #{node['imos_po']['data_services']['celeryd']['max_tasks']}"
    directory node['imos_po']['data_services']['celeryd']['dir']
    user      node['imos_po']['data_services']['user']
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

log_file_user  = node['imos_po']['data_services']['user']
log_file_group = node['imos_po']['data_services']['group']

logrotate_app "project-officer-processing" do
  rotate     node['logrotate']['global']['rotate']
  create     "644 #{log_file_user} #{log_file_group}"
  path       log_file
  frequency  'daily'
  options    [ "compress", "delaycompress", "missingok", "sharedscripts" ]
  rotate     365
end

logrotate_app "project-officer-processing-file-reports" do
  rotate     node['logrotate']['global']['rotate']
  create     "644 #{log_file_user} #{log_file_group}"
  path       ::File.join(log_dir, "*", "*.log")
  frequency  'daily'
  options    [ "compress", "delaycompress", "missingok", "sharedscripts" ]
  rotate     365
end

if Chef::Config[:dev]
  # Change ownership of /mnt to vagrant, so the production hierarchy can be
  # created (/mnt/opendap/1, etc)
  execute "fix opendap permissions" do
    command "mkdir -p #{node['imos_po']['data_services']['opendap_dir']}/1 && chown vagrant:vagrant #{node['imos_po']['data_services']['opendap_dir']}/1"
  end

  # Create watched directories in incoming directory
  watchlists = Chef::Recipe::WatchJobs.get_watches(data_services_watch_dir)
  watchlists.each do |job_name, watchlist|
    watchlist['path'].each do |path|
      path = ::File.join(node['imos_po']['data_services']['incoming_dir'], path)
      ::FileUtils.mkdir_p path
      ::FileUtils.chown 'vagrant', 'vagrant', path
    end
  end
end
