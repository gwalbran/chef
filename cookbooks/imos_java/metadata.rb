name              "imos_java"
maintainer        "eMII"
maintainer_email  "developers@emii.org.au"
license           "Apache 2.0"
description       "Wraps install of Java runtime."
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "1.5.4"

recipe "default", "Installs Java runtime"

depends "java"

%w{ debian ubuntu centos redhat scientific fedora amazon arch freebsd }.each do |os|
  supports os
end
