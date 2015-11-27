name             "imos_jenkins"
maintainer       "IMOS"
maintainer_email "developers@emii.org.au"
license          "All rights reserved"
description      "Installs/Configures jenkins"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.3"

%w{ imos_core imos_java imos_devel imos_po jenkins apt xvfb imos_postgresql git imos_backup packer rbenv ruby_build }.each do |cb|
  depends cb
end

recipe "imos_jenkins::default", "Installs and configures a Jenkins instance"
