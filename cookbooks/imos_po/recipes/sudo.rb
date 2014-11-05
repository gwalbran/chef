#
# Cookbook Name:: imos_po
# Recipe:: sudo
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#
# Allows project officer group to sudo

sudo 'projectofficer' do
  group    "projectofficer"
  runas    "root"
  commands node['imos_po']['sudo_commands']
  host     "ALL"
  nopasswd true
end
