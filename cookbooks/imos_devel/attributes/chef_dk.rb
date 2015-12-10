default['imos_devel']['chef_dk']['version']         = '0.10.0'
default['imos_devel']['chef_dk']['package_name']    = "chefdk_#{node['imos_devel']['chef_dk']['version']}-1_amd64.deb"
default['imos_devel']['chef_dk']['source_url']      = "https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/12.04/x86_64/#{node['imos_devel']['chef_dk']['package_name']}"
default['imos_devel']['chef_dk']['source_checksum'] = 'beb1db9fe097997970b4731325a5eb5bbd0a047fccf393e2aeaf472ae809cee3'
