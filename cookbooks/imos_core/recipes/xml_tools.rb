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

deps = %w{build-essential libxml2-dev libxslt1-dev zlib1g-dev liblzma-dev binutils-doc bison unzip gettext flex ncurses-dev}

if node[:lsb]['codename'].include?("precise")
  ruby_dev_pkg = 'ruby1.9.1-dev'
else
  ruby_dev_pkg = 'ruby-dev'
end
deps.push(ruby_dev_pkg)

# Those ar needed to compile nokogiri
deps.each do |pkg|
  # Use this method to install packages immediately rather than after
  # `chef_gem` resources
  pkg_resource = package pkg do
    action :nothing
  end
  pkg_resource.run_action(:install)
end

chef_gem 'nokogiri'
