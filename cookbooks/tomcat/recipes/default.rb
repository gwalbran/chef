#
# Cookbook Name:: tomcat
# Recipe:: default
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

include_recipe "imos_java"

# Create user
user node['tomcat']['user'] do
  system true
end

# Create CATALINA_HOME
directory node['tomcat']['home'] do
  owner     node['tomcat']['user']
  group     node['tomcat']['group']
  recursive true
  mode      00755
end

execute "remove tomcat7_ init.d" do
  command "rm -f /etc/init.d/tomcat7_*"
end
