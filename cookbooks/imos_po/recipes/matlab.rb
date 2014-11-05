#
# Cookbook Name:: imos_po
# Recipe:: matlab
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#
# Sets up a server to allow project officers to do data manipulation

%w{matlab mbuild mcc mex}.each do |exe|
  link_to   = File.join(node['imos_po']['matlab_dir'], "bin", exe)
  link_from = File.join("/usr/local/bin", exe)

  link link_from do
    to    link_to
    owner "root"
    group "root"
  end
end

