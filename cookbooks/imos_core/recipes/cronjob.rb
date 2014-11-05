#
# Cookbook Name:: imos_core
# Recipe:: cronjobs
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

service "cron" do
  action [ :enable, :start ]
end

node['cronjobs'].each do |job|
  cron_d job['job_name'] do
    minute job['minute']    || "*"
    hour job['hour']        || "*"
    day job['day']          || "*"
    month job['month']      || "*"
    weekday job['weekday']  || "*"
    command job['command']
    user job['user']        || "root"
    mailto job['mailto']    || "sys.admin@emii.org.au"
    path job['path']
    home job['home']
    shell job['shell']
  end
end if node['cronjobs']
