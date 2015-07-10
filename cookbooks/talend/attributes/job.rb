#
# Cookbook Name:: talend
# resource:: deploy
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#

default['talend']['mailto'] = "developers.emii.org.au"

default['talend']['user']  = "talend"
default['talend']['group'] = "talend"

default['talend']['base_dir']    = "/usr/local/talend"
default['talend']['bin_dir']     = "#{node['talend']['base_dir']}/bin"
default['talend']['etc_dir']     = "#{node['talend']['base_dir']}/etc"
default['talend']['jobs_dir']    = "#{node['talend']['base_dir']}/jobs"
default['talend']['working']     = "#{node['talend']['base_dir']}/data"
default['talend']['rubbish_dir'] = "#{node['talend']['base_dir']}/rubbish"

default['talend']['mocked_config_regexps'] = {
  ".*_Server$"        => "localhost",
  "Metadata_Username" => "admin",
  "Metadata_Password" => "admin",
  "Metadata_URL"      => "http://localhost:8080/geonetwork"
}

default['talend']['max_parallel_jobs'] = node['cpu']['total'] ? node['cpu']['total'].to_i : 2
default['talend']['task_spooler_url']  = "http://ftp.ubuntu.com/ubuntu/pool/universe/t/task-spooler/task-spooler_0.7.4-1_amd64.deb"

# Start harvesters at 18:00 daily
default['talend']['hour']   = "18"
default['talend']['minute'] = "0"

default['talend']['common_parameters'] = {}
# No talend environment implies production environment
default['talend']['environment'] = "prod"

default['talend']['trigger']['bin']    = ::File.join(node['talend']['bin_dir'], "talend-trigger")
default['talend']['trigger']['config'] = ::File.join(node['talend']['etc_dir'], "trigger.conf")
