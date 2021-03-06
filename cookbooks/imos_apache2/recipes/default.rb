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
  mode      0755
  recursive true
end

include_recipe 'apache2'
include_recipe 'imos_apache2::fix_awstats_conf_file'
include_recipe 'imos_apache2::static_content'
include_recipe 'imos_apache2::vhosts'

# Disable unwanted confs on xenial
if node[:lsb]['codename'].include?("xenial")
  apache_config 'localized-error-pages' do
    enable false
  end
  apache_config 'other-vhosts-access-log' do
    enable false
  end
  apache_config 'serve-cgi-bin' do
    enable false
  end
end
