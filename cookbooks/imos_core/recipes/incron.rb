#
# Cookbook Name:: imos_core
# Recipe:: incron
#

# Install incron from jenkins
incron_filename  = File.basename(node['imos_core']['incron']['url'])
incron_full_path = File.join(Chef::Config[:file_cache_path], incron_filename)

remote_file incron_full_path do
  source node['imos_core']['incron']['url']
  mode   0644
  action :create_if_missing
end

dpkg_package incron_full_path do
  source incron_full_path
end

