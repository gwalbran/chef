name              "imos_layer_seeder"
maintainer        "IMOS"
maintainer_email  "developers@emii.org.au"
license           "Apache 2.0"
description       "Installs a layer seeding script for Geowebcache, and a cron job that runs it"
version           "1.0.0"


%w{ }.each do |cb|
  depends cb
end
