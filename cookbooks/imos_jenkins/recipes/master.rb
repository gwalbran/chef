#
# Cookbook Name:: jenkins
# Recipe:: master
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Recipe to configure a jenkins master node.

include_recipe 'jenkins::master'

include_recipe 'imos_jenkins::node_common'
include_recipe "imos_jenkins::backup"
