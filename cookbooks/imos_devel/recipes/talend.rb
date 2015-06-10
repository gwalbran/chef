#
# Cookbook Name:: imos_devel
# Recipe:: talend
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#

package 'zip'

talend_pkg_cache = ::File.join(Chef::Config[:file_cache_path], ::File.basename(node['imos_devel']['talend']['source_url']))
remote_file talend_pkg_cache do
  source   node['imos_devel']['talend']['source_url']
  checksum node['imos_devel']['talend']['source_checksum']
  mode     0644
  action   :create_if_missing
end

talend_extracted_dir = talend_pkg_cache.split('.')[0...-1].join('.')
execute "unpack_talend" do
  command "unzip -q -u -o -d #{Chef::Config[:file_cache_path]} #{talend_pkg_cache} && mv #{talend_extracted_dir} #{node['imos_devel']['talend']['install_dir']}"
  not_if { ::File.exist?(node['imos_devel']['talend']['install_dir']) }
end

# SDI plugins for talend
talend_sdi_pkg_cache = ::File.join(Chef::Config[:file_cache_path], ::File.basename(node['imos_devel']['talend']['sdi_source_url']))
remote_file talend_sdi_pkg_cache do
  source   node['imos_devel']['talend']['sdi_source_url']
  checksum node['imos_devel']['talend']['sdi_source_checksum']
  mode     0644
  action   :create_if_missing
end

talend_sdi_extracted_dir = talend_sdi_pkg_cache.split('.')[0...-1].join('.')
talend_sdi_plugins_dir = ::File.join(node['imos_devel']['talend']['install_dir'], "plugins", "org.talend.libraries.sdi_4.2.0")
execute "unpack_talend_sdi" do
  command "unzip -q -u -o -d #{Chef::Config[:file_cache_path]} #{talend_sdi_pkg_cache} && mv #{talend_sdi_extracted_dir}/plugins/* #{node['imos_devel']['talend']['install_dir']}/plugins/ && rm -rf #{talend_sdi_extracted_dir}"
  not_if { ::File.exist?(talend_sdi_plugins_dir) }
end

# Codegen plugin for talend
talend_codegen_basename = ::File.basename(node['imos_devel']['talend']['codegen_source_url'])
remote_file ::File.join(node['imos_devel']['talend']['install_dir'], "plugins", talend_codegen_basename) do
  source   node['imos_devel']['talend']['codegen_source_url']
  checksum node['imos_devel']['talend']['codegen_source_checksum']
  mode     0644
  action   :create_if_missing
end

# Chown the talend directory to the desired user
execute "chown_talend_dir" do
  command "chown -R #{node['imos_devel']['talend']['user']} #{node['imos_devel']['talend']['install_dir']}"
  only_if { node['imos_devel']['talend']['user'] != "root" && node['imos_devel']['talend']['install_dir'] != "/" }
end
