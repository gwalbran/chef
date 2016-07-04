default['imos_po']['netcdf_checker']['dir']           = "/usr/local/bin"
default['imos_po']['netcdf_checker']['repo']          = "https://github.com/ioos/compliance-checker.git"
default['imos_po']['netcdf_checker']['branch']        = "master"
default['imos_po']['netcdf_checker']['executable']    = "/usr/local/bin/netcdf-checker"
default['imos_po']['netcdf_checker']['version'] = '2.2.0'
default['imos_po']['netcdf_checker']['url'] = "https://ci.aodn.org.au/job/compliance_checker/lastSuccessfulBuild/artifact/dist/compliance_checker-#{default['imos_po']['netcdf_checker']['version']}-py2.7.egg"
default['imos_po']['netcdf_checker']['cc_plugin_ver'] = '0.9.0'
default['imos_po']['netcdf_checker']['cc_plugin_url'] = "https://ci.aodn.org.au/job/compliance_checker_plugin_imos/lastSuccessfulBuild/artifact/lib/cc_plugin_imos/dist/cc_plugin_imos-#{default['imos_po']['netcdf_checker']['cc_plugin_ver']}-py2.7.egg"
