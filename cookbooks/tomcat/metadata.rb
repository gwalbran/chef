name             "tomcat"
maintainer       "IMOS"
maintainer_email "developers@emii.org.au"
license          "Apache 2.0"
description      "Installs/Configures tomcat"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.12.0"

%w{ imos_java imos_webapps logrotate }.each do |cb|
  depends cb
end

%w{ debian ubuntu centos redhat fedora }.each do |os|
  supports os
end

recipe "tomcat::default", "Installs and configures Tomcat"
recipe "tomcat::users", "Setup users and roles for Tomcat"
