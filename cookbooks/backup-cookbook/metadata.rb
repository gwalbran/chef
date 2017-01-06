name             'backup'
maintainer       'Dan Fruehauf'
maintainer_email 'malkodan@gmail.com'
license          'GPLv2'
description      'Installs/Configures backup rock'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'
recipe           'backup::default', 'Default simple recipe'

depends 'git'

%w{ debian ubuntu centos fedora redhat scientific }.each do |os|
  supports os
end
