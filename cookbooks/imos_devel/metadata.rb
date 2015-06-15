name             "imos_devel"
maintainer       "IMOS"
maintainer_email "developers@emii.org.au"
license          "All rights reserved"
description      "Recipes required to run a development node"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"

%w{ imos_core apt xvfb ruby_build rbenv imos_postgresql git packer }.each do |cb|
  depends cb
end
