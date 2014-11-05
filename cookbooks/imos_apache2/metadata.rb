name             'imos_apache2'
maintainer       'IMOS'
maintainer_email 'developers@emii.org.au'
license          'All rights reserved'
description      'Installs/Configures imos_apache2'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

%w{ apache2 awstats logrotate }.each do |cookbook|
  depends cookbook
end
