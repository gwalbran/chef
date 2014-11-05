#
# Cookbook Name:: imos_apache2
# Recipe:: default
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

# Create directory before all the apache recipes, as it might be on /mnt/ebs
# and require some handling (unlike /var/log)
# Make sure the log dir is traversable by awstats
directory node['apache']['log_dir'] do
  mode 0755
  recursive true
end

include_recipe 'apache2'
include_recipe 'imos_apache2::fix_awstats_conf_file'
