#
# Cookbook Name:: imos_po
# Recipe:: data_services
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#
# Sets up a server to allow project officers to do data manipulation

package 'heirloom-mailx'

# Use this so we can deploy private repositories
include_recipe "imos_core::git_deploy_key"

data_services_dir = node['imos_po']['data_services']['dir']
data_services_log_dir = node['imos_po']['data_services']['log_dir']
data_services_cron_dir = File.join(data_services_dir, "cron.d")

git data_services_dir do
  repository  node['imos_po']['data_services']['repo']
  revision    node['imos_po']['data_services']['branch']
  action      :sync
  user        'root'
  group       'projectofficer'
  ssh_wrapper node['git_ssh_wrapper']
  notifies    :create, "ruby_block[data_services_cronjobs]", :immediately
end

directory data_services_log_dir do
  user      'root'
  group     'projectofficer'
  mode      01777
  recursive true
end

# Inject those variables to the cronjobs
cron_vars = [
    "OPENDAP_DIR='#{node['imos_po']['data_services']['opendap_dir']}'",
    "PUBLIC_DIR='#{node['imos_po']['data_services']['public_dir']}'",
    "ARCHIVE_DIR='#{node['imos_po']['data_services']['archive_dir']}'",
    "INCOMING_DIR='#{node['imos_po']['data_services']['incoming_dir']}'",
    "WIP_DIR='#{node['imos_po']['wip_dir']}'",
    "DATA_SERVICES_DIR='#{data_services_dir}'",
    "LOG_DIR='#{data_services_log_dir}'"
]

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
        node['vagrant'] # mocked or not (will affect MAILTO= line)
      )

      if File.exists?(data_services_dir) && File.exists?(data_services_cron_dir)
        Dir.foreach(data_services_cron_dir) do |cronjob|
          next if cronjob == '.' or cronjob == '..'

          cronjob_full_path = File.join(data_services_cron_dir, cronjob)
          cronjob_dest      = File.join("/etc/cron.d", "_po_#{cronjob}")

          # Run those scripts as 'nobody'!
          cronjob_sanitizer.sanitize_cronjob_file(cronjob_full_path, cronjob_dest, data_services_dir, cron_vars)
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