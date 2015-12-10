#
# Cookbook Name:: imos_webapps
# Definition:: thredds
#
# Copyright 2012, IMOS
#
# All rights reserved - Do Not Redistribute
#

define :thredds do

  def thredds_config_file(thredds_config_base, source, destination, app_parameters, instance_service_name)
    template ::File.join(thredds_config_base, destination) do
      cookbook  "external_templates"
      source    "thredds/#{source}.erb"
      owner     node['tomcat']['user']
      group     node['tomcat']['group']
      mode      00644
      backup    3
      variables ({
        :root => app_parameters['root']
      })
      notifies :restart, "service[#{instance_service_name}]", :delayed
    end
  end

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

  # Main catalog file
  thredds_config_file(thredds_config_base, app_parameters['catalog'], "catalog.xml", app_parameters, instance_service_name)

  # Other configuration files (usually referenced by catalog.xml)
  if app_parameters['config_files']
    app_parameters['config_files'].each do |config_file|
      thredds_config_file(thredds_config_base, config_file, config_file, app_parameters, instance_service_name)
    end
  end

  # Cache directory
  link "#{thredds_config_base}/cache" do
    to app_parameters['cache_dir']
  end

  directory app_parameters['cache_dir'] do
    owner     node['tomcat']['user']
    group     node['tomcat']['group']
    mode      0755
    recursive true
  end
end
