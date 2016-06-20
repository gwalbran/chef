default['imos_po']['netcdf_checker']['dir']           = "/var/lib/netcdf-checker"
default['imos_po']['netcdf_checker']['repo']          = "https://github.com/ioos/compliance-checker.git"
default['imos_po']['netcdf_checker']['branch']        = "master"
default['imos_po']['netcdf_checker']['executable']    = "/usr/local/bin/netcdf-checker"
default['imos_po']['netcdf_checker']['cc_plugin_dir'] = ::File.join(node['imos_po']['data_services']['dir'], "lib", "cc_plugin_imos")
