apt_repository 'openjdk-r' do
  uri          'http://ppa.launchpad.net/openjdk-r/ppa/ubuntu'
  distribution "#{node['lsb']['codename']}"
  components   ['main']
  keyserver    'keyserver.ubuntu.com'
  key          '86F44E2A'
end

# This is required to run Java 7 on Xenial. May be removed when Java is upgraded to version 8.
# Ref: http://askubuntu.com/questions/795901/what-happened-to-tzdata-java-in-xenial-16-04
if node[:lsb]['codename'].include?("xenial")
  apt_repository 'tzdata-java-xenial' do
    uri          'http://ppa.launchpad.net/justinludwig/tzdata/ubuntu'
    distribution "#{node['lsb']['codename']}"
    components   ['main']
    keyserver    'keyserver.ubuntu.com'
    key          '451DE0A4'
  end
  apt_package 'tzdata-java'
end

include_recipe "java::set_attributes_from_version"
include_recipe "java::#{node['java']['install_flavor']}"
