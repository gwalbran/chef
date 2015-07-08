#
# Cookbook Name:: imos_core
# Recipe:: dev
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

Chef::Config[:dev] = true
include_recipe "imos_core::insecure"
