#
# Cookbook Name:: talend
# resource:: deploy
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#

require 'rubygems'
require 'json'
require 'net/http'

actions :configure, :deploy, :schedule, :remove

default_action :deploy

# Common name (none-unique) of job
attribute :common_name, :kind_of => String, :required => true

# config attributes
attribute :bin_dir, :kind_of => String, :required => true
attribute :jobs_dir, :kind_of => String, :required => true
attribute :data_dir, :kind_of => String, :required => true
attribute :rubbish_dir, :kind_of => String

attribute :delimiter, :kind_of => String, :default => "=>"
attribute :params, :kind_of => Hash
attribute :harvest_resources, :kind_of => [Hash, NilClass]

# deployment attributes
attribute :artifact_id, :kind_of => String
attribute :owner, :regex => Chef::Config['user_valid_regex'], :default => node['talend']['user']
attribute :group, :regex => Chef::Config['group_valid_regex'], :default => node['talend']['group']

# scheduling attributes
attribute :cron_job, :kind_of => String
attribute :context, :kind_of => String

attribute :process_owner,:regex => Chef::Config['user_valid_regex'], :default => node['talend']['user']
attribute :process_group, :regex => Chef::Config['group_valid_regex'], :default => node['talend']['group']

attribute :minute, :kind_of => [Integer, String], :default => node['talend']['minute']
attribute :hour, :kind_of => [Integer, String], :default => node['talend']['hour']
attribute :day, :kind_of => [Integer, String], :default => "*"
attribute :month, :kind_of => [Integer, String], :default => "*"
attribute :weekday, :kind_of => [Integer, String], :default => "*"

attribute :mailto, :kind_of => [String, NilClass]
attribute :path, :kind_of => [String, NilClass]
attribute :home, :kind_of => [String, NilClass]
attribute :shell, :kind_of => [String, NilClass]
