name             'imos_postgresql'
maintainer       'IMOS'
maintainer_email 'jfca@utas.edu.au'
license          'All rights reserved'
description      'Installs/Configures imos_postgresql'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.2.0'

%w{ backup }.each do |cb|
  depends cb
end
