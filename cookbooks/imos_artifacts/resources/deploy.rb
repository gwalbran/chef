#
# Cookbook Name:: imos_artifacts
# resource:: deploy
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#

actions :deploy

default_action :deploy

# installation identification

attribute :artifact_id, :name_attribute => true, :required => true, :kind_of => String
attribute :artifact_manifest, :required => false, :kind_of => Hash, :default => nil

# deployment attributes
attribute :install_dir,                :kind_of => String
attribute :file_destination,           :kind_of => String
attribute :owner,                      :regex => Chef::Config['user_valid_regex'], :default => "root"
attribute :group,                      :regex => Chef::Config['group_valid_regex'], :default => "root"
attribute :remove_top_level_directory, :kind_of => [ TrueClass, FalseClass ], :default => false
attribute :cached_artifact,            :kind_of => String, :required => false
