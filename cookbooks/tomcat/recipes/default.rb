#
# Cookbook Name:: tomcat
# Recipe:: default
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

include_recipe "imos_java"

tomcat_version = node['tomcat']['version']

# Create user
user node['tomcat']['user'] do
  system true
end

# Create CATALINA_HOME
directory node['tomcat']['home'] do
  owner     node['tomcat']['user']
  group     node['tomcat']['user']
  recursive true
  mode      00755
end
