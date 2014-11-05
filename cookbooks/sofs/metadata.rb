name             "sofs"
maintainer       "IMOS"
maintainer_email "developers@emii.org.au"
license          "All rights reserved"
description      "Installs/Configures Southern Ocean Flux Station plot imagery web site"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"

%w{ git application imos_core imos_apache2 }.each do |cb|
  depends cb
end
