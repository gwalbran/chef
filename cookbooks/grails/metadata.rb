name             "grails"
maintainer       "IMOS"
maintainer_email "developers@emii.org.au"
license          "All rights reserved"
description      "Installs/Configures grails"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"

%w{ apt }.each do |cb|
  depends cb
end

recipe "grails::default", "Installs grails"
