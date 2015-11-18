#
# Cookbook Name:: imos_artifacts
# Recipe:: default
#
# Copyright 2012, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Simple default recipe
#

# Needed to build ruby gems
include_recipe "build-essential"

chef_gem 'aws-sdk'
chef_gem 'nokogiri'

package 'unzip'
