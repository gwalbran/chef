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

# Fix for: http://stackoverflow.com/questions/28987891/patch-pyopenssl-for-sslv3-issue
python_package 'pip' do
  action :upgrade
end

python_package 'pyopenssl' do
  action :remove
end
