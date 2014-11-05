name             "imos_users"
maintainer       "IMOS"
maintainer_email "developers@emii.org.au"
license          "All rights reserved"
description      "Manage users"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"

%w{ sudo users }.each do |cookbook|
  depends cookbook
end
