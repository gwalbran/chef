default['imos_devel']['chef_dk']['version']         = '0.6.0'
default['imos_devel']['chef_dk']['package_name']    = "chefdk_#{node['imos_devel']['chef_dk']['version']}-1_amd64.deb"
default['imos_devel']['chef_dk']['source_url']      = "https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/12.04/x86_64/#{node['imos_devel']['chef_dk']['package_name']}"
default['imos_devel']['chef_dk']['source_checksum'] = 'cd8c92b9649835100a81101a2476423a4da3145b1cbbacc845c8e21413115feb'
