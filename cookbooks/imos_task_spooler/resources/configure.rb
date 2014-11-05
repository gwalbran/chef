#
# Cookbook Name:: imos_task_spooler
# resource:: configure
#
# Copyright (C) 2014 IMOS
#
# All rights reserved - Do Not Redistribute
#

actions        :max_jobs
default_action :max_jobs

attribute :max_jobs, :kind_of => Integer, :required => true
attribute :user,     :kind_of => String,  :required => true
