#
# Cookbook Name:: imos_po
# Recipe:: packages
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#
# Install packages for data-services

node['imos_po']['data_services']['packages'].each do |pkg|
  package pkg
end
