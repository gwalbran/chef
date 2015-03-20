#
# Cookbook Name:: talend
# Recipe:: default
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

def get_job_common_name(job_name, data_bag_item)
  return data_bag_item['common_name'] || job_name.gsub(/_rc$/, '')
end

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

  environment = node['talend']['environment']

  # Use job parameters, override with environment specific if exists
  bag_item = data_bag_item("talend", job_name)
  job_parameters = bag_item['params'].dup
  if bag_item[environment] && bag_item[environment]['params']
    job_parameters.merge!(bag_item[environment]['params'])
  end

  # Use job scheduling from data bag, override with environment specific
  cron = {}
  if bag_item['cron']
    cron.merge!(bag_item['cron'])
  end
  if bag_item[environment] && bag_item[environment]['cron']
    cron.merge!(bag_item[environment]['cron'])
  end

  job_common_name = get_job_common_name(job_name, bag_item)

  # If artifact_id is defined, use data bag, otherwise assemble one
  artifact_id = bag_item['artifact_id']
  artifact_manifest = nil
  if ! artifact_id
    artifact_id = job_name
    artifact_manifest = {
      "id"       => job_name,
      "job"      => bag_item['jenkins_job'] || node['talend']['jenkins_job'],
      "filename" => bag_item['artifact_filename']
    }
  end

  job_id = "#{job_name}-#{artifact_id}"
  job_dir = ::File.join(jobs_dir, job_id)

  talend_job job_id do
    action            :deploy
    common_name       job_common_name
    artifact_id       bag_item['artifact_id']
    artifact_manifest artifact_manifest
    jobs_dir          jobs_dir
    data_dir          data_dir
    bin_dir           bin_dir
  end

  talend_job job_id do
    action            :configure
    common_name       job_common_name
    params            job_parameters
    delimiter         bag_item['delimiter']
    harvest_resources bag_item['resources']
    jobs_dir          jobs_dir
    data_dir          data_dir
    bin_dir           bin_dir
  end

  talend_job job_id do
    action      :schedule
    common_name job_common_name
    hour        cron['hour']
    weekday     cron['weekday']
    minute      cron['minute']
    day         cron['day']
    month       cron['month']
    mailto      bag_item['mailto'] || node['talend']['mailto']
    jobs_dir    jobs_dir
    data_dir    data_dir
    bin_dir     bin_dir
  end

  installed_talend_jobs << job_id

end

# Time to cleanup unused talend directories
existing_talend_job_dirs = File.exist?(jobs_dir) ? Dir.entries(jobs_dir).select { |dir_name| dir_name != '.' && dir_name != '..' } : []
job_to_cleanup = existing_talend_job_dirs - installed_talend_jobs

job_to_cleanup.each do |job_id|
  talend_job job_id do
    action      :remove
    common_name job_id
    jobs_dir    jobs_dir
    rubbish_dir rubbish_dir
  end
end

# Configure task spooler
include_recipe "talend::task_spooler"
