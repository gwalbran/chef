name             "imos_webapps"
maintainer       "IMOS"
maintainer_email "developers@emii.org.au"
license          "All rights reserved"
description      "Installs/Configures imos_webapps"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "1.0.6"

%w{ imos_artifacts imos_core imos_apache2 imos_java tomcat backup git }.each do |cookbook|
  depends cookbook
end
