#
# Cookbook Name:: imos_devel
# Recipe:: compliance_checker
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

package 'python-virtualenv'

# Install Compliance Checker prerequisites from requirements.txt
requirements_filename  = File.basename(node['imos_devel']['compliance_checker']['python_requirements_url'])
requirements_full_path = File.join(Chef::Config[:file_cache_path], requirements_filename)

remote_file requirements_full_path do
  source   node['imos_devel']['compliance_checker']['python_requirements_url']
  mode     0644
  action   :create_if_missing
end

pip_requirements requirements_full_path
