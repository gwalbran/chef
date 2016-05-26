#
# Cookbook Name:: imos_webapps
# Recipe:: generic_webapp
#
# Copyright 2012, IMOS
#
# All rights reserved - Do Not Redistribute
#

include_recipe "imos_artifacts"
include_recipe "imos_apache2"
include_recipe "tomcat"

# Make sure the user includes recipe[ssl], we're not going to do it for him
if ! Chef::Config[:dev] && !node.run_list.include?("recipe[ssl]")
  Chef::Application.fatal!("Your node must include recipe[ssl]")
end

# Make sure the user includes recipe[imos_squid], we're not going to do it for him
if node['webapps'] && node['webapps']['instances']
  node['webapps']['instances'].each do |instance|
    if instance['cached'] && !node.run_list.include?("recipe[imos_squid]")
      Chef::Application.fatal!("You have a cached application, so you must include recipe[imos_squid]")
    end
  end
end

# Business begins here
configured_instances = []
configured_ports     = []

if node['webapps'] && node['webapps']['instances']
  node['webapps']['instances'].each do |instance|

    instance_parameters        = instance
    instance_name              = instance['name']
    instance_default_app       = instance['default_app']
    instance_proxy_exclusions  = instance['proxy_exclusions']
    instance_vhost             = instance['vhost']
    instance_aliases           = instance['aliases']
    instance_tomcat_port       = instance['port']
    instance_base_directory    = "#{node['tomcat']['base']}/#{instance_name}"
    instance_service_name      = "tomcat_#{instance_name}"
    instance_data_directory    = instance_parameters['data_dir'] || "#{instance_base_directory}/data/#{instance_name}"
    instance_apps              = instance['apps']
    instance_httpd_rules       = instance['httpd_rules']

    # Collect instance apps and their aliases to configure with apache (not
    # vhost aliases!!!)
    apps = []
    instance_apps.each do |app|
      apps << { :name => app['name'], :aliases => app['aliases'], :is_default_app => app['name'] == instance_default_app ? 'true' : 'false', :proxy_exclusions => instance_proxy_exclusions }
    end

    # Make sure we don't have port duplicates
    if configured_ports.include? instance_tomcat_port
      Chef::Application.fatal!("Port '#{instance_tomcat_port}' is already in use")
    end

    configured_ports << instance_tomcat_port

    # DNS names that should be configured in the node definition
    dns_names = [ instance_vhost ] + (instance_aliases || [])
    dns_names.each do |dns_name|
      if not node['aliases'].include? dns_name
        if instance_vhost == dns_name && ! instance['ignore_vhost_dns']
          Chef::Log.warn("DNS name '#{dns_name}' not defined in node")
          Chef::Application.fatal!("You can define 'ignore_vhost_dns: true' for the instance if you know what you're doing")
        else
          Chef::Log.warn("DNS name (vhost alias) '#{dns_name}' not defined in node")
        end
      end
    end

    # Apache definitions
    apache_for_webapp instance_name do
      apps        apps
      vhost       instance_vhost
      tomcat_port instance_tomcat_port
      aliases     instance_aliases
      proxy_exclusions instance_proxy_exclusions
      rules       instance_httpd_rules
      cached      instance['cached'] || false
      https       instance['https']  || false
      sts         instance['sts']    || false
      full_config instance
    end

    # Tomcat definitions
    tomcat_instance instance_name do
      instance instance_parameters
    end
    configured_instances << instance_name

    # Build all the web apps
    instance_apps.each do |instance_app|
      app_name               = instance_app['name']
      is_default_app         = instance_app['name'] == instance_default_app ? 'true' : 'false'
      backup                 = instance_app['backup']
      jndis                  = instance_app['jndis']
      artifact               = instance_app['artifact']
      config_template_dir    = instance_app['config_template_dir'] || instance_app['artifact']
      config_file            = instance_app['config_file']
      custom_definition      = instance_app['custom_def']
      custom_template_config = instance_app['custom_templates']

      # Merge parameters declared by the instance, giving precedence to ones
      # declared by this app
      app_parameters = instance_parameters.dup
      app_parameters.merge!(instance_app)

      # Inject default app flag into parameters
      app_parameters[:is_default_app] = is_default_app

      # App specific configuration, we can have many apps on one tomcat instance
      # Artifact setup
      imos_tomcat_webapp app_name do
        application_name     app_name
        is_default_app       is_default_app
        artifact_name        artifact
        jndis                jndis
        backup               backup
        config_template_dir  config_template_dir
        config_file          config_file
        data_directory       app_parameters['data_dir'] || instance_data_directory
        tomcat_instance_name instance_name
        base_directory       instance_base_directory
        service_name         instance_service_name
        custom_parameters    app_parameters
      end

      # Load custom definition if it's specified for application
      if custom_definition
        Chef::Log.info("Trying to include 'imos_webapps::#{custom_definition}' for '#{app_name}'")

        eval ("
          #{custom_definition} '#{instance_service_name}/#{app_name}' do
            instance_parameters     instance
            instance_service_name   instance_service_name
            instance_base_directory instance_base_directory
            instance_port           instance_tomcat_port
            app_parameters          app_parameters
            end
        ")
      end

      # Install custom templates if specified (for example, this can be used for installing XSLT definitions
      # into a geoserver data directory.
      if custom_template_config
        custom_templates app_name do
          templates     custom_template_config
        end
      end

    end

  end
end

# Cleanup previous installations which are no longer in the instance list.
curr_instances = File.exist?(node['tomcat']['base']) ? Dir.entries(node['tomcat']['base']).select { |dir_name| dir_name != '.' && dir_name != '..' } : []
instances_to_delete = curr_instances - configured_instances

instances_to_delete.each do |instance_name|
  delete_tomcat_instance instance_name
end
