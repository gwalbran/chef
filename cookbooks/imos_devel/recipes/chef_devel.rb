#
# Cookbook Name:: imos_devel
# Recipe:: chef_dk
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Recipe to install dependencies required for chef development.
#
include_recipe 'imos_devel::chef_dk'
include_recipe 'imos_devel::vagrant'
include_recipe 'imos_devel::virtualbox'
