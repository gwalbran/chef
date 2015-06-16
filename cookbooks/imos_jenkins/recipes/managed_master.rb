#
# Cookbook Name:: jenkins
# Recipe:: managed_master
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Recipe to configure a fully-chef managed jenkins master node.

include_recipe "imos_java"

node.set['jenkins']['master']['runit']['sv_timeout'] = 240
include_recipe "jenkins::master"

include_recipe "imos_jenkins::keys"
include_recipe "imos_jenkins::authentication"
include_recipe "imos_jenkins::plugins"
include_recipe "imos_jenkins::tools"
include_recipe "imos_jenkins::global_env"
include_recipe "imos_jenkins::jobs"
include_recipe "imos_jenkins::define_slaves"
