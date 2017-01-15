#
# Cookbook Name:: imos_mounts
# Recipe:: ebs
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#

# Create the /mnt/ebs directory
directory "/mnt/ebs" do
  recursive true
end

mount "/mnt/ebs" do
  device node['mounts']['ebs_device']
  fstype "ext4"
  options "defaults"
  action [:mount, :enable]
  only_if { File.exist?(node['mounts']['ebs_device']) }
end

# Mock apache log directory on dev boxes
if Chef::Config[:dev]
  directory "/mnt/ebs/log/apache2" do
    recursive true
  end
end
