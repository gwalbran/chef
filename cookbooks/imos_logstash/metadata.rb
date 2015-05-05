name             "imos_logstash"
maintainer       "IMOS"
maintainer_email "developers@emii.org.au"
license          "All rights reserved"
description      "Configuration of centralised logging and metrics."
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"

%w{
  imos_artifacts
  imos_users
  imos_java
  kibana
  logstash
}.each do |cookbook|
  depends cookbook
end
