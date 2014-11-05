#
# Cookbook Name:: imos_core
# Recipe:: xml_tools
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#

# Wouldn't build ruby gems without it
include_recipe "build-essential"

xsltdev = package "libxslt-dev" do
  action :nothing
end

xmldev = package "libxml2-dev" do
  action :nothing
end

xsltdev.run_action(:install)
xmldev.run_action(:install)

chef_gem 'nokogiri'
