#
# Cookbook Name:: imos_logstash
# Recipe:: server
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#

include_recipe "imos_java"
include_recipe "imos_logstash::indexer"
include_recipe "imos_logstash::kibana"
