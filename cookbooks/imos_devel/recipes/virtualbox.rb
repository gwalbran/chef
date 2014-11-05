#
# Cookbook Name:: imos_devel
# Recipe:: virtualbox
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Recipe to install virtual box
#

# Was previously adding Oracle's virtualbox ubuntu repo ("http://download.virtualbox.org/virtualbox/debian/")
# but this was way too slow/unreliable, so hosting the package on our own ftp server now.
remote_file File.join(Chef::Config[:file_cache_path], node['imos_devel']['virtualbox']['package_name']) do
  source   node['imos_devel']['virtualbox']['source_url']
  checksum node['imos_devel']['virtualbox']['source_checksum']
  action   :create_if_missing
end

%w{ libgl1-mesa-glx libqt4-network libqt4-opengl libqtcore4 libvpx1
    libqtgui4 libsdl1.2debian libsdl1.2debian libxmu6 }.each do |pkg|
  package pkg
end

dpkg_package node['imos_devel']['virtualbox']['package_name'] do
  source File.join(Chef::Config[:file_cache_path], node['imos_devel']['virtualbox']['package_name'])
end
