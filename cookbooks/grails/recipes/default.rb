#
# Cookbook Name:: grails
# Recipe:: default
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

apt_repository "groovy-dev-grails" do
  uri "http://ppa.launchpad.net/groovy-dev/grails/ubuntu"
  keyserver "keyserver.ubuntu.com"
  key "02A9EC29"
  components ["main"]
  distribution "precise"
end

#sudo apt-get update
execute "apt-get update" do
  command "apt-get update"
  ignore_failure true
  action :nothing
end

package "grails-ppa" do
  options "--force-yes"
end

package "grails-1.3.7"  do
  options "--force-yes"
end

# Patch the installation of 1.3.7, so that coverage reports work (on jenkins).
# See: http://comments.gmane.org/gmane.comp.lang.groovy.grails.user/106477
cookbook_file "/usr/share/grails/1.3.7/scripts/_GrailsClasspath.groovy" do
  source "_GrailsClasspath.groovy"
  mode 00644
  owner "root"
  group "root"
end

package "grails-2.1.0"  do
  options "--force-yes"
end

package "grails-2.2.0"  do
  options "--force-yes"
end

package "grails-2.4.4"  do
  options "--force-yes"
end

execute "select grails 1.3.7 as default" do
  command "update-alternatives --set grails /usr/share/grails/1.3.7/bin/grails"
  action :run
end
