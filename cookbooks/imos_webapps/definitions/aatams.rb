#
# Cookbook Name:: imos_webapps
# Definition:: aatams
#
# Copyright 2012, IMOS
#
# All rights reserved - Do Not Redistribute
#

define :aatams do

  app_parameters          = params[:app_parameters]
  instance_parameters     = params[:instance_parameters]
  instance_service_name   = params[:instance_service_name]
  instance_base_directory = params[:instance_base_directory]

  data_dir                = app_parameters['data_dir']

  # Create application directories
  if app_parameters[:data_directories]
    app_parameters[:data_directories].each do |dir|
      directory File.join(data_dir, dir) do
        owner     node['tomcat']['user']
        group     node['tomcat']['group']
        mode      0755
        recursive true
      end
    end
  end

end

