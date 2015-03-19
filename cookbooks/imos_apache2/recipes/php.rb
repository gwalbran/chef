#
# Cookbook Name:: imos_apache2
# Recipe:: php
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#

include_recipe "apache2::mod_php5"

node['imos_apache2']['php']['packages'].each do |php_package|
  package php_package do
    notifies :restart, "service[apache2]", :delayed
  end
end
