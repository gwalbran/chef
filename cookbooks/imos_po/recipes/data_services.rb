#
# Cookbook Name:: imos_po
# Recipe:: data_services
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#
# Sets up a server to allow project officers to do data manipulation

node['imos_po']['data_services']['packages'].each do |pkg|
  package pkg
end

node['imos_po']['data_services']['python']['packages'].each do |python_pkg|
  python_pip python_pkg['name'] do
    version python_pkg['version']
  end
end

data_services_dir = node['imos_po']['data_services']['dir']
data_services_cron_dir = File.join(data_services_dir, "cron.d")

if node['imos_po']['data_services']['clone_repository']
  # Use this so we can deploy private repositories
  include_recipe "imos_core::git_deploy_key"

  git data_services_dir do
    repository  node['imos_po']['data_services']['repo']
    revision    node['imos_po']['data_services']['branch']
    action      :sync
    user        'root'
    group       node['imos_po']['data_services']['group']
    ssh_wrapper node['git_ssh_wrapper']
    notifies    :create, "ruby_block[data_services_cronjobs]", :immediately
  end

else
  # Dummy block to generate the cronjobs when git is not checked out by the recipe
  ruby_block "#{data_services_dir}_dummy" do
    block do end
    notifies :create, "ruby_block[data_services_cronjobs]", :immediately
  end
end

node['imos_po']['data_services']['owned_dirs'].each do |dir|
  directory dir do
    user      node['imos_po']['data_services']['user']
    group     node['imos_po']['data_services']['group']
    mode      01775
    recursive true
  end
end

# Allow anyone in 'projectofficer' group to sudo to user 'projectofficer'
sudo 'data_services' do
  group    "projectofficer"
  runas    node['imos_po']['data_services']['user']
  commands [ "ALL" ]
  host     "ALL"
  nopasswd true
end

# Allow projectofficer user to sudo as talend
sudo 'projectofficer_as_talend' do
  user     node['imos_po']['data_services']['user']
  runas    node['talend']['user']
  commands [ "ALL" ]
  host     "ALL"
  nopasswd true
end

# Inject those variables to the cronjobs
# Please note all variables here must be fully expanded to avoid scripts
# needing to evaluate them at runtime
data_services_vars = {
  'OPENDAP_DIR'       => node['imos_po']['data_services']['opendap_dir'],
  'PUBLIC_DIR'        => node['imos_po']['data_services']['public_dir'],
  'ARCHIVE_DIR'       => node['imos_po']['data_services']['archive_dir'],
  'INCOMING_DIR'      => node['imos_po']['data_services']['incoming_dir'],
  'ERROR_DIR'         => node['imos_po']['data_services']['error_dir'],
  'GRAVEYARD_DIR'     => node['imos_po']['data_services']['graveyard_dir'],
  'OPENDAP_IMOS_DIR'  => node['imos_po']['data_services']['opendap_dir'] + "/1/IMOS/opendap",
  'PUBLIC_IMOS_DIR'   => node['imos_po']['data_services']['public_dir'],
  'ARCHIVE_IMOS_DIR'  => node['imos_po']['data_services']['archive_dir'],
  'WIP_DIR'           => node['imos_po']['wip_dir'],
  'EMAIL_ALIASES'     => node['imos_po']['email_aliases'],
  'DATA_SERVICES_DIR' => data_services_dir,
  'LOG_DIR'           => node['imos_po']['data_services']['log_dir'],
  'S3CMD_CONFIG'      => node['imos_po']['s3']['config_file'],
  'S3_BUCKET'         => node['imos_po']['s3']['bucket'],
  'MAILX_CONFIG'      => node['imos_po']['mailx']['config_file'],
  'HARVESTER_TRIGGER' => "sudo -u #{node['talend']['user']} #{node['talend']['trigger']['bin']} -c #{node['talend']['trigger']['config']}"
}

file "/etc/profile.d/data-services.sh" do
  mode    00644
  user    'root'
  group   'root'
  content "#!/bin/bash
test -f #{data_services_dir}/env && source #{data_services_dir}/env
for file in #{data_services_dir}/profile.d/*; do
    source $file
done
"
end

# plant env file in data-services repo with all related variables
template node['imos_po']['data_services']['env'] do
  source  "env.erb"
  user    node['imos_po']['data_services']['user']
  group   node['imos_po']['data_services']['group']
  mode    00444
  variables ({
    :vars => data_services_vars,
    :lib  => node['imos_po']['data_services']['lib']
  })
end

if node['imos_po']['data_services']['cronjobs']
  # Install cron jobs for project officers
  ruby_block "data_services_cronjobs" do
    block do
      # Remove old cronjobs if there are any
      FileUtils.rm Dir.glob('/etc/cron.d/_po_*')

      allowed_cronjob_users = node['imos_po']['data_services']['cron_allowed_users'].dup
      Users.find_users_in_groups(node['imos_po']['data_services']['cron_allowed_groups']).each do |user|
        allowed_cronjob_users << user['id']
      end
      Chef::Log.info "Allowing cronjobs from '#{allowed_cronjob_users}'"

      cronjob_sanitizer = Chef::Recipe::CronjobSanitizer.new(
        allowed_cronjob_users,
        Chef::Config[:dev] # mocked or not (will affect MAILTO= line)
      )

      if File.exists?(data_services_dir) && File.exists?(data_services_cron_dir)
        Dir.foreach(data_services_cron_dir) do |cronjob|
          next if cronjob == '.' or cronjob == '..'

          cronjob_full_path = File.join(data_services_cron_dir, cronjob)
          cronjob_dest      = File.join("/etc/cron.d", "_po_#{cronjob}")

          # Run those scripts as 'nobody'!
          cronjob_sanitizer.sanitize_cronjob_file(cronjob_full_path, cronjob_dest, data_services_dir, data_services_vars)
        end
      end
    end
    action :nothing
  end
else
  ruby_block "data_services_cronjobs" do
    block do
      Chef::Log.info("data-services cronjobs are disabled")
    end
  end
end

include_recipe "imos_po::watches"
include_recipe "imos_po::mailx"
