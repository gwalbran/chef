name             "imos_chef_solo"
maintainer       "IMOS"
maintainer_email "developers@emii.org.au"
license          "All rights reserved"
description      "chef-solo-search wrapper"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"

depends 'apt'
depends 'chef-solo-search'
