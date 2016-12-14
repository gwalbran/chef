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

  bag_item = data_bag_item("talend", job_name)

  # Use job parameters, override with environment specific if exists
  job_parameters = {}
  bag_item['params'] and job_parameters.merge!(bag_item['params'])
  bag_item[environment] && bag_item[environment]['params'] and job_parameters.merge!(bag_item[environment]['params'])

  # Use job scheduling from data bag, override with environment specific
  cron = {}
  bag_item['cron'] and cron.merge!(bag_item['cron'])
  bag_item[environment] && bag_item[environment]['cron'] and cron.merge!(bag_item[environment]['cron'])

  # Triggering can be enabled for talend job. If enabled, does not schedule as
  # a cron job.  Can specify one event or multiple events which trigger the job
  events = []

  if bag_item[environment] && bag_item[environment]['events']
    # use environment specific events
    events.concat bag_item[environment]['events']
  elsif bag_item[environment] && bag_item[environment]['event']
    # use environment specific event
    events << bag_item[environment]['event']
  elsif bag_item['events']
    # multiple events
    events.concat bag_item['events']
  elsif bag_item['event']
    # single event
    events << bag_item['event']
  end

  trigger = {}
  trigger['cron'] = cron
  trigger['events'] = events

  job_common_name = get_job_common_name(job_name, bag_item)

  artifact_manifest = nil
  if bag_item['artifact_id']
    artifact_manifest = ImosArtifacts::Deployer.get_artifact_manifest(bag_item['artifact_id'])
  elsif bag_item['artifact_filename']
    artifact_id = job_name
    jenkins_job = bag_item['jenkins_job'] || node['talend']['jenkins_job']
    artifact_filename = bag_item['artifact_filename']
    artifact_manifest = ImosArtifacts::Deployer.get_artifact_manifest("#{jenkins_job}/#{artifact_filename}")
  else
    Chef::Application.fatal!("Data bag '#{}' does not have either artifact_id of artifact_filename defined")
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
    trigger     trigger
    mailto      bag_item['mailto'] || node['talend']['mailto']
    jobs_dir    jobs_dir
    data_dir    data_dir
    bin_dir     bin_dir
  end

  installed_talend_jobs << job_id

end

# Time to cleanup unused talend directories and triggers
existing_talend_job_dirs = File.exist?(jobs_dir) ? Dir.entries(jobs_dir).select { |dir_name| dir_name != '.' && dir_name != '..' } : []
existing_talend_triggers = Talend::JobHelper.get_triggers(node['talend']['trigger']['config'])

dirs_to_cleanup = existing_talend_job_dirs - installed_talend_jobs
triggers_to_cleanup = existing_talend_triggers - installed_talend_jobs

jobs_to_cleanup = dirs_to_cleanup + triggers_to_cleanup

jobs_to_cleanup.uniq.each do |job_id|
  talend_job job_id do
    action      :remove
    common_name job_id
    jobs_dir    jobs_dir
    rubbish_dir rubbish_dir
  end
end

# Configure task spooler
include_recipe "talend::task_spooler"
