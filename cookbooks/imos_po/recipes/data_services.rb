#
# Cookbook Name:: imos_po
# Recipe:: data_services
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#
# Sets up a server to allow project officers to do data manipulation

include_recipe "imos_po::packages"

data_services_dir = node['imos_po']['data_services']['dir']
data_services_cron_dir = File.join(data_services_dir, "cron.d")

if node['imos_po']['data_services']['clone_repository']
  # Use this so we can deploy private repositories
  include_recipe "imos_core::git_deploy_key"

  git "data_services" do
    destination data_services_dir
    repository  node['imos_po']['data_services']['repo']
    revision    node['imos_po']['data_services']['branch']
    action      :sync
    user        'root'
    group       node['imos_po']['data_services']['group']
    ssh_wrapper node['git_ssh_wrapper']
  end
end

python_requirements = ::File.join(data_services_dir, "requirements.txt")
execute "python_requirements" do
  command    "cat #{python_requirements} | xargs -n 1 pip install"
  subscribes :run, 'git[data_services]', :delayed
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

harvester_trigger_cmd = "/bin/true"
if node['talend']
  sudo 'projectofficer_as_talend' do
    user     node['imos_po']['data_services']['user']
    runas    node['talend']['user']
    commands [ "ALL" ]
    host     "ALL"
    nopasswd true
  end

  harvester_trigger_cmd = "sudo -u #{node['talend']['user']} #{node['talend']['trigger']['bin']} -c #{node['talend']['trigger']['config']}"
end

s3cmd = "s3cmd --config=#{node['imos_po']['s3']['config_file']}"
if Chef::Config[:dev]
  s3cmd = "s3cmd-mocked"
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
  'DATA_DIR'          => node['imos_po']['data_services']['data_dir'],
  'S3CMD'             => s3cmd,
  'S3_BUCKET'         => node['imos_po']['s3']['bucket'],
  'MAILX_CONFIG'      => node['imos_po']['mailx']['config_file'],
  'HARVESTER_TRIGGER' => harvester_trigger_cmd
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
  mode    00644
  variables ({
    :vars => data_services_vars,
    :lib  => node['imos_po']['data_services']['lib']
  })
end

if ! node['imos_po']['data_services']['cronjobs'].empty?
  # Install cron jobs for project officers
  ruby_block "data_services_cronjobs" do
    block do
      allowed_cronjob_users = node['imos_po']['data_services']['cron_allowed_users'].dup
      Users.find_users_in_groups(node['imos_po']['data_services']['cron_allowed_groups']).each do |user|
        allowed_cronjob_users << user['id']
      end
      Chef::Log.info "Allowing cronjobs from '#{allowed_cronjob_users}'"

      cronjob_sanitizer = Chef::Recipe::CronjobSanitizer.new(
        allowed_cronjob_users,
        Chef::Config[:dev] # mocked or not (will affect MAILTO= line)
      )

      cronjob_prefix = node['imos_po']['data_services']['cronjob_prefix']

      cronjobs = []
      node['imos_po']['data_services']['cronjobs'].each do |cronjob_pattern|
        Dir.glob(::File.join(data_services_cron_dir, cronjob_pattern)).each do |cronjob|
          cronjobs << ::File.basename(cronjob)
        end
      end

      Chef::Log.info("Configuring cronjobs '#{cronjobs}'")

      if File.exists?(data_services_dir) && File.exists?(data_services_cron_dir)
        Dir.mktmpdir { |tmp_cronjobs|
          cronjobs.uniq.each do |cronjob|
            next if cronjob == '.' or cronjob == '..'

            Chef::Log.info("Configuring cronjob '#{cronjob}'")
            cronjob_full_path = File.join(data_services_cron_dir, cronjob)
            cronjob_dest      = File.join(tmp_cronjobs, "#{cronjob_prefix}#{cronjob}")

            cronjob_sanitizer.sanitize_cronjob_file(cronjob_full_path, cronjob_dest, data_services_dir, data_services_vars)
          end

          crond_base = "/etc/cron.d"
          existing_cronjobs = Dir.chdir(crond_base)   { Dir.glob("#{cronjob_prefix}*") }
          new_cronjobs =      Dir.chdir(tmp_cronjobs) { Dir.glob("#{cronjob_prefix}*") }

          # Figure out what jobs needs to be deleted, delete only them
          cronjobs_to_delete = existing_cronjobs - new_cronjobs
          Dir.chdir(crond_base) { FileUtils.rm_f(cronjobs_to_delete) }

          Dir.chdir(tmp_cronjobs) { FileUtils.mv(new_cronjobs, crond_base, :force => true) }
        }
      end
    end
    subscribes :create, 'git[data_services]', :immediately
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
