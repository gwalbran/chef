#
# Cookbook Name:: imos_core
# Recipe:: locale
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#

execute "locale" do
  command "locale-gen #{node['imos_core']['locale']['lang']} && update-locale"
end
