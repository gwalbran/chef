#
# Cookbook Name:: talend
# Recipe:: task_spooler
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#
# No default recipe for this cookbook.  This cookbook provides resources for
# other cookbooks to use

include_recipe "imos_task_spooler"

imos_task_spooler_configure node['talend']['user'] do
  action   :max_jobs
  user     node['talend']['user']
  max_jobs node['talend']['max_parallel_jobs']
end

cron "clear_task_spooler_queue" do
  user    node['talend']['user']
  command node['imos_task_spooler']['clear_command']
  minute  0
  hour    7
  weekday 6
end
