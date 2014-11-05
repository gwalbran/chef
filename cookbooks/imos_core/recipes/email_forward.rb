#
# Cookbook Name:: imos_core
# Recipe:: email_forward
#
# Copyright 2013, IMOS
#

file "/root/.forward" do
  owner "root"
  group "root"
  mode "0660"
  content node[:email_forward][:email_address]
  action :create
end

# If we configure some email forwarding, then make sure we don't get any
# annoying emails from logwatch!!
package "logwatch" do
  action :purge
end
