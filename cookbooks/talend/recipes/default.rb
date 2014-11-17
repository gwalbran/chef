#
# Cookbook Name:: talend
# Recipe:: default
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

require 'fileutils'

include_recipe "imos_java"
include_recipe "imos_artifacts"
include_recipe "talend::essentials"

talend_user  = node['talend']['user']
talend_group = node['talend']['group']
jobs_dir     = node['talend']['jobs_dir']
data_dir     = node['talend']['working']
bin_dir      = node['talend']['bin_dir']
rubbish_dir  = node['talend']['rubbish_dir']

# Start with a clean slate
execute "purge_talend_jobs" do
  user    talend_user
  command "crontab -r"
  only_if { 
    `id -u #{talend_user} 2> /dev/null && crontab -l -u #{talend_user} > /dev/null`
    $?.success?
  }
end

installed_talend_jobs = []

node['talend']['jobs'].each do |job_name|

  # eg. argo, cpr, soop-xbt etc
  bag_item = data_bag_item("talend", job_name)

  job_id = "#{job_name}-#{bag_item['artifact_id']}"
  job_dir = ::File.join(jobs_dir, job_id)

  talend_job job_id do
    action      :deploy
    artifact_id bag_item['artifact_id']
    jobs_dir    jobs_dir
    data_dir    data_dir
    bin_dir     bin_dir
  end

  talend_job job_id do
    action            :configure
    params            bag_item['params']
    delimiter         bag_item['delimiter']
    harvest_resources bag_item['resources']
    jobs_dir          jobs_dir
    data_dir          data_dir
    bin_dir           bin_dir
  end

  # Allow empty scheduling in data bag
  if ! bag_item['cron']
    bag_item['cron'] = {}
  end

  talend_job job_id do
    action  :schedule
    hour     bag_item['cron']['hour']
    weekday  bag_item['cron']['weekday']
    minute   bag_item['cron']['minute']
    day      bag_item['cron']['day']
    month    bag_item['cron']['month']
    mailto   bag_item['mailto'] || node['talend']['mailto']
    jobs_dir jobs_dir
    data_dir data_dir
    bin_dir  bin_dir
  end

  installed_talend_jobs << job_id

end

# Time to cleanup unused talend directories
existing_talend_job_dirs = File.exist?(jobs_dir) ? Dir.entries(jobs_dir).select { |dir_name| dir_name != '.' && dir_name != '..' } : []
job_to_cleanup = existing_talend_job_dirs - installed_talend_jobs

job_to_cleanup.each do |job_id|
  talend_job job_id do
    action      :remove
    jobs_dir    jobs_dir
    rubbish_dir rubbish_dir
  end
end

# Configure task spooler
include_recipe "talend::task_spooler"