default['imos_devel']['vagrant']['version']            = '1.6.5'
default['imos_devel']['vagrant']['package_name']       = 'vagrant_1.6.5_x86_64.deb'
default['imos_devel']['vagrant']['source_url']         = "https://dl.bintray.com/mitchellh/vagrant/#{node['imos_devel']['vagrant']['package_name']}"
default['imos_devel']['vagrant']['source_checksum']    = 'e2c7af6d032ac551ebd6399265cb9cb64402c9fb96a12289161b7f67afada28a'

default['imos_devel']['virtualbox']['package_name']    = 'virtualbox-4.3_4.3.6-91406~Ubuntu~precise_amd64.deb'
default['imos_devel']['virtualbox']['source_url']      = "http://download.virtualbox.org/virtualbox/4.3.6/#{node['imos_devel']['virtualbox']['package_name']}"
default['imos_devel']['virtualbox']['source_checksum'] = '9aeb5210ebf009d906b66c942a3eff4ee38db7bf'

default['imos_devel']['berkshelf']['version']          = '3.1.2'

default['imos_devel']['vagrant']['plugins']            = []

# Base directory for sources
default['imos_devel']['src']                           = "/vagrant/src"

# User and home directory to use for development
default['imos_devel']['user']                          = "vagrant"
default['imos_devel']['homedir']                       = "/home/vagrant"
