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
