#
# Cookbook Name:: imos_task_spooler
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#

default['imos_task_spooler']['url'] = "http://ftp.ubuntu.com/ubuntu/pool/universe/t/task-spooler/task-spooler_0.7.4-1_amd64.deb"

default['imos_task_spooler']['command']           = "tsp"
default['imos_task_spooler']['clear_command']     = "#{node['imos_task_spooler']['command']} -C"
default['imos_task_spooler']['tsp_if_not_queued'] = "/usr/local/bin/tsp-if-not-queued"
