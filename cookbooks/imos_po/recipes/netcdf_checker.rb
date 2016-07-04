#
# Cookbook Name:: imos_po
# Recipe:: netcdf_checker
#
# Copyright (C) 2015 IMOS
#
# All rights reserved - Do Not Redistribute
#
# Deploys the IOOS netcdf checker

netcdf_checker_filename  = File.basename(node['imos_po']['netcdf_checker']['url'])
netcdf_checker_full_path = File.join(Chef::Config[:file_cache_path], netcdf_checker_filename)

remote_file netcdf_checker_full_path do
  source   node['imos_po']['netcdf_checker']['url']
  mode     0644
  action   :create_if_missing
end

# NOTE: the easy_install_package in 12.0.3 does not appear to work correctly, hence the not ideal option of executing
#       via a shell command directly
# TODO: (when Chef upgraded) check the behaviour of easy_install_package again in order to perform this action cleanly
execute "install compliance-checker" do
  user 'root'
  command "easy_install --always-unzip #{netcdf_checker_full_path}"
  not_if "test $(pip show compliance-checker | awk /^Version:/'{print $2}') = #{node['imos_po']['netcdf_checker']['version']}"
end

# NOTE: despite the fact that the setup.py defines a console entry point, that does not appear to work, so this link has
#       been retained to support the current expectation
link node['imos_po']['netcdf_checker']['executable'] do
  to ::File.join(node['imos_po']['netcdf_checker']['dir'], "cchecker.py")
end

cc_plugin_filename  = File.basename(node['imos_po']['netcdf_checker']['cc_plugin_url'])
cc_plugin_full_path = File.join(Chef::Config[:file_cache_path], cc_plugin_filename)

remote_file cc_plugin_full_path do
  source   node['imos_po']['netcdf_checker']['cc_plugin_url']
  mode     0644
  action   :create_if_missing
end

execute "install cc-plugin-imos" do
  user 'root'
  command "easy_install --always-unzip #{cc_plugin_full_path}"
  not_if "test $(pip show cc-plugin-imos | awk /^Version:/'{print $2}') = #{node['imos_po']['netcdf_checker']['cc_plugin_ver']}"
end
