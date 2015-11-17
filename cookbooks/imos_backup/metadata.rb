name             "imos_backup"
maintainer       "IMOS"
maintainer_email "developers@emii.org.au"
license          "All rights reserved"
description      "Installs/Configures backup"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"

%w{ backup logrotate imos_core imos_users }.each do |cb|
  depends cb
end
