name              "imos_squid"
maintainer        "IMOS"
maintainer_email  "developers@emii.org.au"
license           "Apache 2.0"
description       "Installs and configures squid for IMOS"
version           "1.0.0"

recipe "imos_squid::default", "Installs generic squid configuration"

%w{ squid logrotate }.each do |cb|
  depends cb
end
