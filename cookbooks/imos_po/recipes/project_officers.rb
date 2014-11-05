#
# Cookbook Name:: imos_po
# Recipe:: project_officers
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#
# Sets up a server to allow project officers to do data manipulation

# TODO REMOVE THIS RECIPE!!!!

directory "/etc/cron.d" do
  group "projectofficer"
  mode  00775
end

directory "/usr/local/bin" do
  group     "projectofficer"
  mode      00775
  recursive true
end

