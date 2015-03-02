#
# Cookbook Name:: jenkins
# Recipe:: master
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Recipe to configure a fully-chef managed jenkins master node.
include_recipe "imos_java"
include_recipe "jenkins::master"

include_recipe "imos_jenkins::authentication"
