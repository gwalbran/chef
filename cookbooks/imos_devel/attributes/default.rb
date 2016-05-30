default['imos_devel']['vagrant']['version']            = '1.7.4'
default['imos_devel']['vagrant']['package_name']       = "vagrant_#{node['imos_devel']['vagrant']['version']}_x86_64.deb"
default['imos_devel']['vagrant']['source_url']         = "https://releases.hashicorp.com/vagrant/#{node['imos_devel']['vagrant']['version']}/#{node['imos_devel']['vagrant']['package_name']}"
default['imos_devel']['vagrant']['source_checksum']    = 'dcd2c2b5d7ae2183d82b8b363979901474ba8d2006410576ada89d7fa7668336'

default['imos_devel']['virtualbox']['package_name']    = 'virtualbox-4.3_4.3.6-91406~Ubuntu~precise_amd64.deb'
default['imos_devel']['virtualbox']['source_url']      = "http://download.virtualbox.org/virtualbox/4.3.6/#{node['imos_devel']['virtualbox']['package_name']}"
default['imos_devel']['virtualbox']['source_checksum'] = '7817f8ee7263e3c9e0dbfaa7b33a5787608ebe6c726cb71e9a29ed409ca29bc3'

default['imos_devel']['berkshelf']['version']          = '3.1.2'

default['imos_devel']['vagrant']['plugins']            = []

# Base directory for sources
default['imos_devel']['src']                           = "/vagrant/src"

# User and home directory to use for development
default['imos_devel']['user']                          = "vagrant"
default['imos_devel']['homedir']                       = "/home/vagrant"
