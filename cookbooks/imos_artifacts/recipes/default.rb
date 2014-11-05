#
# Cookbook Name:: artifact
# Recipe:: default
#
# Copyright 2012, IMOS
#
# All rights reserved - Do Not Redistribute
#
# No default recipe.  This cookbook provides lwrp's
# for use in other cookbooks

# Needed to build ruby gems
include_recipe "build-essential"

chef_gem 'nokogiri'
package 'unzip'
