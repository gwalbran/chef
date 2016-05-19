#
# Copyright 2012, IMOS
#
# All rights reserved - Do Not Redistribute
#

define :imos_tomcat_webapp do
  application_name     = params[:application_name]
  is_default_app       = params[:is_default_app]
  artifact_name        = params[:artifact_name]
  data_directories     = params[:data_directories]
  config_template_dir  = params[:config_template_dir]
  config_file          = params[:config_file]
  jndis                = params[:jndis] || []
  backup               = params[:backup] || false
  base_directory       = params[:base_directory]
  service_name         = params[:service_name]
  data_directory       = params[:data_directory]
  custom_parameters    = params[:custom_parameters]
  tomcat_instance_name = params[:tomcat_instance_name]

  # Configuration file defined?
  if node[application_name] && node[application_name]['config_file']
    config_file = node[application_name]['config_file']
  end

  jndi_resources = []
  # All jndi resources specifed in the 'jndis' entry in the webapp
  # The first one will be the "main" one from which we might create a local
  # database if needed
  jndis.each do |jndi_name|
    begin
      Chef::Log.info("Using JNDI resource '#{jndi_name}' from data bag for '#{application_name}'")
      jndi_resource = Chef::EncryptedDataBagItem.load('jndi_resources', jndi_name).to_hash
      if Chef::Config[:dev] && params[:custom_parameters][:mock_jndis] != false
        # Mock JNDI on dev boxes to point to localhost
        jndi_resource['url'].gsub!(/:\/\/.*:/, "://localhost:")
      end
      jndi_resources << jndi_resource
    end
  end

  # Data directory, may be mounted outside of the tomcat directory
  if node[application_name] && node[application_name]['data_dir']
    tomcat_data_directory = "#{node[application_name]['data_dir']}/#{application_name}"
  end

  # Install war & context xml into place
  imos_tomcat_context artifact_name do
    app_name             application_name
    is_default_app       is_default_app
    tomcat_instance_name tomcat_instance_name
    service_name         service_name
    parallel_deploy      custom_parameters['parallel_deploy']
    config_template_dir  config_template_dir
    config_file_name     config_file
    base_directory       base_directory
    template_variables   ({
      :custom_parameters     => custom_parameters,
      :is_default_app        => is_default_app,
      :tomcat_instance_name  => tomcat_instance_name,
      :tomcat_base_directory => base_directory,
      :tomcat_data_directory => data_directory,
      :jndi_resources        => jndi_resources
    })
  end

  directory data_directory do
    owner     node['tomcat']['user']
    group     node['tomcat']['group']
    mode      0755
    recursive true
  end

  # Backup the data directory
  if backup && (node.run_list.include?("role[backup]") || node.run_list.include?("role[restore]"))
    Chef::Log.info("Configuring backup for application '#{application_name}' with directory '#{data_directory}'")
    backup "#{tomcat_instance_name}_#{application_name}" do
      cookbook "imos_backup"
      params   ({:files => [data_directory]})
    end
  end

end
