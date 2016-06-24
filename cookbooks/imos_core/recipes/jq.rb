#
# Cookbook Name:: imos_core
# Recipe:: jq
#
# Copyright 2016, IMOS
#
# All rights reserved - Do Not Redistribute
#

# Install JQ from backports repository
# Note: This is a stopgap solution to avoid enabling the whole 'precise-backports' repo.
#       This is not an issue in Xenial, as it has been added to 'universe'.
jq_filename  = File.basename(node['imos_core']['jq']['url'])
jq_full_path = File.join(Chef::Config[:file_cache_path], jq_filename)

remote_file jq_full_path do
  source   node['imos_core']['jq']['url']
  mode     0644
  action   :create_if_missing
end

dpkg_package jq_full_path do
  source jq_full_path
end

