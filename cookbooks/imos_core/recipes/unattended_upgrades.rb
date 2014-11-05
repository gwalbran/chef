#
# Cookbook Name:: imos_core
# Recipe:: unattended_upgrades
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

include_recipe "unattended_upgrades"

# Override the original cookbook with our new template
begin
  r = resources(:template => "/etc/apt/apt.conf.d/50unattended-upgrades")
  r.cookbook "imos_core"
rescue Chef::Exceptions::ResourceNotFound
  Chef::Log.warn "imos_core::unattended_upgrades could not find template to override!"
end
