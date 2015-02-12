#
# Cookbook Name:: imos_devel
# Recipe:: grails
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Recipe to install grails/gvm and some more aliases
#

user = node['imos_devel']['grails']['user']
homedir = node['imos_devel']['grails']['homedir']

package "unzip"

# Install GVM
execute "install_gvm" do
  command "su - #{user} -c 'curl -s get.gvmtool.net | /bin/bash'"
  not_if "test -d #{homedir}/.gvm"
  action :run
end

template "/etc/profile.d/imos_dev.sh" do
  content "imos_dev.sh.erb"
  mode    00644
  user    'root'
  group   'root'
end
