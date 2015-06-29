name             "imos_po"
maintainer       "IMOS"
maintainer_email "developers@emii.org.au"
license          "All rights reserved"
description      "Installs/Configures imos_po"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"

%w{ imos_mounts imos_core imos_users python sudo logrotate rsyslog }. each do |cb|
  depends cb
end
