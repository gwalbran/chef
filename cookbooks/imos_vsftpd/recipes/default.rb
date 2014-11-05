#
# Cookbook Name:: imos_vsftpd
# Recipe:: default
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#

include_recipe "vsftpd"
include_recipe "imos_vsftpd::ftp_dir_tree"
include_recipe "imos_vsftpd::pam"

# Override the original cookbook with our new template
begin
  r = resources(:template => '/etc/vsftpd.conf')
  r.source "vsftpd.conf.erb"
  r.cookbook "imos_vsftpd"
rescue Chef::Exceptions::ResourceNotFound
  Chef::Log.warn "imos_vsftpd could not find template to override!"
end

include_recipe "imos_vsftpd::vusers"
