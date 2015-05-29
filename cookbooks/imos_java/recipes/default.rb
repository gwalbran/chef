apt_repository 'openjdk-r' do
  uri          'http://ppa.launchpad.net/openjdk-r/ppa/ubuntu'
  distribution "#{node['lsb']['codename']}"
  components   ['main']
  keyserver    'keyserver.ubuntu.com'
  key          '86F44E2A'
end

include_recipe "java::set_attributes_from_version"
include_recipe "java::#{node['java']['install_flavor']}"
