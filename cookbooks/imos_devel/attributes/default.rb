default['imos_devel']['vagrant']['version']            = '1.6.2'
default['imos_devel']['vagrant']['package_name']       = 'vagrant_1.6.2_x86_64.deb'
default['imos_devel']['vagrant']['source_url']         = "https://dl.bintray.com/mitchellh/vagrant/#{node['imos_devel']['vagrant']['package_name']}"
default['imos_devel']['vagrant']['source_checksum']    = '1599113509b3ab2b13ca219c3bd29bd2fb91b7eb328629ef85036ef5f52677c4'

default['imos_devel']['virtualbox']['package_name']    = 'virtualbox-4.3_4.3.6-91406~Ubuntu~precise_amd64.deb'
default['imos_devel']['virtualbox']['source_url']      = "http://download.virtualbox.org/virtualbox/4.3.6/#{node['imos_devel']['virtualbox']['package_name']}"
default['imos_devel']['virtualbox']['source_checksum'] = '9aeb5210ebf009d906b66c942a3eff4ee38db7bf'

default['imos_devel']['berkshelf']['version']          = '3.1.2'

default['imos_devel']['vagrant']['plugins']            = []
