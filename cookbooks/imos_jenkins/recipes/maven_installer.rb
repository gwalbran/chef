#
# Cookbook Name:: jenkins
# Recipe:: maven_installer
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#

maven_installer = Chef::Recipe::JenkinsHelper.groovy_code_for_tool_installer(
  node['imos_jenkins']['maven']['versions'],
  "hudson.tasks",
  "Maven",
  "Maven.MavenInstaller",
  "Maven.MavenInstallation"
)

jenkins_script 'maven autoinstaller' do
  command maven_installer
end
