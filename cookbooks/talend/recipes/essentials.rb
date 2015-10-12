#
# Cookbook Name:: talend
# Recipe:: essentials
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

# Create talend user/group
talend_user  = node['talend']['user']
talend_group = node['talend']['group']
jobs_dir     = node['talend']['jobs_dir']
log_dir      = node['talend']['log_dir']
config_dir   = node['talend']['config_dir']
data_dir     = node['talend']['working']
bin_dir      = node['talend']['bin_dir']
rubbish_dir  = node['talend']['rubbish_dir']
etc_dir      = node['talend']['etc_dir']

group talend_group

user talend_user do
  home     "/home/#{talend_user}"
  group    talend_group
  shell    "/bin/bash"
  supports :manage_home => true
end

# Create all relevant talend directories
[ jobs_dir, data_dir, bin_dir, rubbish_dir, etc_dir ].each do |dir|
  directory dir do
    owner     talend_user
    group     talend_group
    mode      0755
    recursive true
    action    :create
  end
end

# Essentials binaries/scripts
cookbook_file ::File.join(bin_dir, "run_job.sh") do
  source "run_job.sh"
  owner  talend_user
  group  talend_group
  mode   0755
end

# Allow project officers to invoke commands as talend
sudo 'projectofficers_talend' do
  group     'projectofficer'
  runas     talend_user
  commands  ["ALL"]
  host      "ALL"
  nopasswd  true
end

# Include bash aliases
include_recipe "talend::bash_aliases"
