name             "ramadda"
maintainer       "IMOS"
maintainer_email "developers@emii.org.au"
license          "All rights reserved"
description      "Installs/Configures RAMADDA"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "1.0.1"

%w{ imos_artifacts }.each do |cb|
  depends cb
end

recipe "ramadda::default", "Installs and configures a RAMADDA client"
