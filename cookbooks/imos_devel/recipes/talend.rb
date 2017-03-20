#
# Cookbook Name:: imos_devel
# Recipe:: talend
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#

package 'zip'

def install_talend_pkg(pkg_desc)
  talend_pkg_basename = ::File.basename(pkg_desc['source_url'])
  talend_pkg_cache_file = ::File.join(Chef::Config[:file_cache_path], talend_pkg_basename)

  remote_file talend_pkg_cache_file do
    source   pkg_desc['source_url']
    mode     0644
    notifies :run, "execute[deploy_talend_pkg_#{talend_pkg_basename}]", :immediately
  end

  install_to = ::File.join(node['imos_devel']['talend']['install_dir'], pkg_desc['install_to'])

  if pkg_desc['unzip']
    unzip_filter = pkg_desc['unzip_filter'] or ""
    Chef::Log.info "Unpacking '#{talend_pkg_cache_file}' -> '#{install_to}' using filter '#{unzip_filter}'"
    execute "deploy_talend_pkg_#{talend_pkg_basename}" do
      command "tmp_dir=`mktemp -d` && unzip -q -u -o -d $tmp_dir #{talend_pkg_cache_file} && mkdir -p #{install_to} && cp -a $tmp_dir/#{unzip_filter} #{install_to} && rm -rf --preserve-root $tmp_dir"
      action :nothing
    end
  else
    Chef::Log.info "Copying '#{talend_pkg_cache_file}' -> '#{install_to}'"
    puts "cp #{talend_pkg_cache_file} #{install_to}"
    execute "deploy_talend_pkg_#{talend_pkg_basename}" do
      command "mkdir -p #{install_to} && cp #{talend_pkg_cache_file} #{install_to}"
      action :nothing
    end
  end

end

node['imos_devel']['talend']['packages'].each do |pkg_desc|
  install_talend_pkg(pkg_desc)
end

# Chown the talend directory to the desired user
execute "chown_talend_dir" do
  command "chown -R #{node['imos_devel']['talend']['user']} #{node['imos_devel']['talend']['install_dir']}"
  only_if { node['imos_devel']['talend']['user'] != "root" && node['imos_devel']['talend']['install_dir'] != "/" }
end
