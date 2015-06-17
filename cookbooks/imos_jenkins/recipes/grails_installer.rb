#
# Cookbook Name:: jenkins
# Recipe:: grails_installer
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#

grails_installer = Chef::Recipe::JenkinsHelper.groovy_code_for_tool_installer(
  node['imos_jenkins']['grails']['versions'],
  "com.g2one.hudson.grails",
  "GrailsInstallation",
  "GrailsInstaller",
  "GrailsInstallation"
)

jenkins_script 'grails autoinstaller' do
  command grails_installer
end
