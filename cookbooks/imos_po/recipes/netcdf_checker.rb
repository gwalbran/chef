#
# Cookbook Name:: imos_po
# Recipe:: netcdf_checker
#
# Copyright (C) 2015 IMOS
#
# All rights reserved - Do Not Redistribute
#
# Deploys the IOOS netcdf checker

git node['imos_po']['netcdf_checker']['dir'] do
  repository node['imos_po']['netcdf_checker']['repo']
  revision   node['imos_po']['netcdf_checker']['branch']
  action     :sync
  user       'root'
  group      node['imos_po']['data_services']['group']
end

link node['imos_po']['netcdf_checker']['executable'] do
  to ::File.join(node['imos_po']['netcdf_checker']['dir'], "cchecker.py")
end

Chef::Log.info("Installing IMOS Compliance Checker Plugin")
execute "install_cc_plugin_imos" do
  cwd node['imos_po']['netcdf_checker']['cc_plugin_dir']
  command "pip install -e ."
  subscribes :run, 'git[data_services]', :immediately
  user 'root'
end
Chef::Log.info("Finished installing IMOS Compliance Checker Plugin")
