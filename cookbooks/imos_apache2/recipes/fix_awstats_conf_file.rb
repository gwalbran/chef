#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'awstats'

# This snippet will fix awstats from upstream, which puts the config file at
# /etc/apache2/conf.d/awstats, however apache2 will include
# /etc/apache2/conf.d/*.conf only so the we'll need to simply include here
# /etc/apache2/conf.d/awstats.conf

cookbook_file "/etc/apache2/conf.d/awstats.conf" do
  source   "awstats"
  cookbook "awstats"
  owner    "root"
  group    "root"
  mode     00644
  notifies :restart, resources(:service => "apache2")
end

# Delete the original awstats file as it is not needed
awstats_default_config_file = '/etc/awstats/awstats.conf'
file awstats_default_config_file do
  action :delete
end

# Create awstats directory if it's not created already
awstats_dir = node['imos_apache2']['awstats_dir']
directory awstats_dir do
  mode      00755
  owner     node['apache']['user']
  group     node['apache']['group']
  recursive true
end
