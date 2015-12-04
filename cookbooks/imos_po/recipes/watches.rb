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

po_user  = node['imos_po']['data_services']['user']
po_group = node['imos_po']['data_services']['group']

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
    :user  => po_user,
    :group => po_group
  })
end

ruby_block "verify_watched_directories" do
  block do
    all_paths = []
    watchlists = Chef::Recipe::WatchJobs.get_watches(data_services_watch_dir)
    watchlists.each do |job_name, watchlist|
      watchlist['path'].each do |path|
        all_paths << ::File.join(node['imos_po']['data_services']['incoming_dir'], path)
      end
    end

    missing_paths = all_paths.select { |path| ! ::File.directory?(path) }

    if ! missing_paths.empty? && ! node['imos_po']['data_services']['create_watched_directories']
      Chef::Log.warn("Watched pathes do not exist: '#{missing_paths}'")
    else
      missing_paths.each do |path|
        ::FileUtils.mkdir_p path
        ::FileUtils.chown po_user, po_group, path
      end
    end
  end
end

if node['imos_po']['data_services']['watches']
  package 'incron' do # TODO remove after incron was removed from hosts
    action :remove
  end

  include_recipe 'rabbitmq'
  package 'lsof'
  package 'python-pyinotify'

  ruby_block "create_error_directories" do
    block do
      all_paths = []
      watchlists = Chef::Recipe::WatchJobs.get_watches(data_services_watch_dir)
      watchlists.each do |job_name, watchlist|
        watchlist['path'].each do |path|
          path = ::File.join(node['imos_po']['data_services']['error_dir'], job_name)
          ::FileUtils.mkdir_p path
          ::FileUtils.chown po_user, po_group, path
          ::FileUtils.chmod 00775, path
        end
      end
    end
  end

  directory node['imos_po']['data_services']['celeryd']['dir']

  # Celeryd configuration
  python_pip "celery"
  python_pip "boto"
  include_recipe "supervisor"

  celery_config = node['imos_po']['data_services']['celeryd']['config']

  template node['imos_po']['data_services']['celeryd']['tasks'] do
    source     "tasks.py.erb"
    variables  ({
      :celery_config     => ::File.basename(celery_config),
      :watchlists        => Chef::Recipe::WatchJobs.get_watches(data_services_watch_dir),
      :data_services_dir => data_services_dir
    })
    subscribes :create, 'git[data_services]', :delayed
    notifies   :create, "ruby_block[celery_po_supervisor]"
  end

  backend = node['imos_po']['data_services']['celeryd']['backend']
  password_data_bag = node['imos_po']['data_services']['celeryd']['password_data_bag']
  if Chef::Config[:dev]
    password_data_bag = nil
    backend = "rabbitmq"
  end

  template celery_config do
    source    "celeryconfig.py.erb"
    variables ({
      :watchlists        => Chef::Recipe::WatchJobs.get_watches(data_services_watch_dir),
      :password_data_bag => password_data_bag,
      :backend           => backend
    })
    notifies  :create, "ruby_block[celery_po_supervisor]"
  end

  cookbook_file node['imos_po']['data_services']['celeryd']['inotify'] do
    cookbook "imos_po"
    source   "inotify.py"
    mode     00755
  end

  template node['imos_po']['data_services']['celeryd']['inotify-config'] do
    source    "inotify-config.py.erb"
    variables ({
      :watchlists => Chef::Recipe::WatchJobs.get_watches(data_services_watch_dir),
    })
    subscribes :create, 'git[data_services]', :delayed
  end

  supervisor_service "inotify_po" do
    command    node['imos_po']['data_services']['celeryd']['inotify']
    directory  node['imos_po']['data_services']['celeryd']['dir']
    user       po_user
    action     [:enable, :restart]
    subscribes :create, 'git[data_services]', :delayed
  end

  supervisor_service "celery_po" do # TODO This is here to clean the previously declared resource
    action :disable
  end

  # Why in a ruby_block? Because we need to be able to notify the resource
  # creation AFTER the data-services git repository was updated. This is the
  # only sane way unfortunately.
  ruby_block "celery_po_supervisor" do
    block do
      Chef::Recipe::WatchJobs.get_watches(data_services_watch_dir).each do |job_name, watchlist|
        f = Chef::Resource::SupervisorService.new("celery_po_#{job_name}", run_context)
        f.autostart true
        f.command "celeryd --queues=#{job_name} --config=#{celery_config} -A tasks -c #{node['imos_po']['data_services']['celeryd']['max_tasks']}"
        f.directory node['imos_po']['data_services']['celeryd']['dir']
        f.user po_user
        f.run_action :enable
        f.run_action :restart
      end
    end
    subscribes :create, 'git[data_services]',     :delayed
    subscribes :create, 'python_pip[supervisor]', :delayed
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
  create     "644 #{po_user} #{po_group}"
  path       log_file
  frequency  'daily'
  options    [ "compress", "delaycompress", "missingok", "sharedscripts" ]
  rotate     365
end

logrotate_app "project-officer-processing-file-reports" do
  rotate     node['logrotate']['global']['rotate']
  create     "644 #{po_user} #{po_group}"
  path       ::File.join(log_dir, "*", "*.log")
  frequency  'daily'
  options    [ "compress", "delaycompress", "missingok", "sharedscripts" ]
  rotate     365
end

if Chef::Config[:dev]
  # TODO remove once completely on s3 and not moving files to /mnt/opendap
  ruby_block "create_mocked_directories" do
    block do
      [
        ::File.join(node['imos_po']['data_services']['opendap_dir'], "1"),
        node['imos_po']['data_services']['archive_dir']
      ].each do |path|
        ::FileUtils.mkdir_p path
        ::FileUtils.chown po_user, po_group, path
        ::FileUtils.chmod 00775, path
      end
    end
  end
end
