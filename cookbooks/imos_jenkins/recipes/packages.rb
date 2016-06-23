#
# Cookbook Name:: imos_jenkins
# Recipe:: packages
#
# Copyright (C) 2016 IMOS
#
# All rights reserved - Do Not Redistribute
#
# Install packages for node_common

node['imos_jenkins']['node_common']['packages'].each do |pkg|
  package pkg
end
