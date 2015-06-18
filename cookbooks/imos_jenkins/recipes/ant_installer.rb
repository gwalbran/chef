#
# Cookbook Name:: jenkins
# Recipe:: ant_installer
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#

ant_installer = Chef::Recipe::JenkinsHelper.groovy_code_for_tool_installer(
  node['imos_jenkins']['ant']['versions'],
  "hudson.tasks",
  "Ant",
  "Ant.AntInstaller",
  "Ant.AntInstallation"
)

jenkins_script 'ant autoinstaller' do
  command ant_installer
end
