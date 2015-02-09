#
# Cookbook Name:: imos_apache2
# Recipe:: static_content
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#

# Static directory
directory node['imos_apache2']['static_dir'] do
  mode      0755
  recursive true
end

# A simple robots.txt to deny everything
file ::File.join(node['imos_apache2']['static_dir'], "robots.txt") do
  mode    0644
  content "User-agent: *
Disallow: /
"
end
