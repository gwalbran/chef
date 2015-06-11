#
# Cookbook Name:: imos_devel
# Recipe:: chef_dk
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Recipe to install Chef Development Kit
#

is_chef_dk_in_correct_version = "dpkg-query -W -f='${Version}' chefdk | grep #{node['imos_devel']['chef_dk']['version']}"

# Install chef_dk
remote_file File.join(Chef::Config[:file_cache_path], node['imos_devel']['chef_dk']['package_name']) do
  source   node['imos_devel']['chef_dk']['source_url']
  mode     0644
  checksum node['imos_devel']['chef_dk']['source_checksum']
  action   :create_if_missing
end

dpkg_package node['imos_devel']['chef_dk']['package_name'] do
  source File.join(Chef::Config[:file_cache_path], node['imos_devel']['chef_dk']['package_name'])
  not_if is_chef_dk_in_correct_version
end

# Install knife-solo for the chefdk environment
gem_package "knife-solo" do
  gem_binary "/opt/chefdk/embedded/bin/gem"
  # Install globally, so can be used by all users, not just root
  options    "--no-user-install"
end
