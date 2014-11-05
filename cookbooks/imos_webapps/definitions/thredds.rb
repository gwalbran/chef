#
# Cookbook Name:: imos_webapps
# Definition:: thredds
#
# Copyright 2012, IMOS
#
# All rights reserved - Do Not Redistribute
#

define :thredds do

  app_parameters          = params[:app_parameters]
  instance_parameters     = params[:instance_parameters]
  instance_service_name   = params[:instance_service_name]
  instance_base_directory = params[:instance_base_directory]

  instance_vhost          = instance_parameters['vhost']
  data_dir                = app_parameters['data_dir']
  app_name                = app_parameters['name']

  # Configuration directory
  thredds_config_base = "#{instance_base_directory}/content/thredds"

  directory thredds_config_base do
    owner     node['tomcat']['user']
    group     node['tomcat']['group']
    mode      0755
    recursive true
  end

  # Configuration files
  config_files = [
    "catalog.xml",
    "threddsConfig.xml",
    "climatology.xml",
    "dep.xml",
    "dsto.xml",
    "imas.xml",
    "srs.xml",
    "wms_config.xml"
  ]

  config_files.each do |config_file|
    template "#{thredds_config_base}/#{config_file}" do
      source   "#{app_parameters['artifact']}/#{config_file}.erb"
      owner    node['tomcat']['user']
      group    node['tomcat']['group']
      mode     00644
      backup   3
      variables ({
        :root => app_parameters['root']
      })
      notifies :restart, "service[#{instance_service_name}]", :delayed
    end
  end

  # Cache directory
  link "#{thredds_config_base}/cache" do
    to app_parameters['cache_dir']
  end

end
