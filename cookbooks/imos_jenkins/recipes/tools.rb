#
# Cookbook Name:: jenkins
# Recipe:: tools
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Build configuration required on master

include_recipe "imos_jenkins::maven_installer"
include_recipe "imos_jenkins::grails_installer"
include_recipe "imos_jenkins::ant_installer"
include_recipe "imos_jenkins::xvfb_installer"
include_recipe "imos_jenkins::node_common"
