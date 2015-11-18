#
# Cookbook Name:: imos_artifacts
# Resource:: s3
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#

actions :cache

default_action :cache

attribute :id, :name_attribute => true, :required => true, :kind_of => String
attribute :manifest, :required => false, :kind_of => Hash, :default => nil
