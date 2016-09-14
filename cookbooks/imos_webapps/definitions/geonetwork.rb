#
# Cookbook Name:: imos_webapps
# Definition:: geonetwork
#
# Copyright 2012, IMOS
#
# All rights reserved - Do Not Redistribute
#

define :geonetwork do
  app_parameters          = params[:app_parameters]
  instance_parameters     = params[:instance_parameters]
  instance_service_name   = params[:instance_service_name]
  instance_base_directory = params[:instance_base_directory]
  instance_port           = params[:instance_port]

  data_dir                = app_parameters['data_dir']
  app_name                = app_parameters['name']

  config_dir              = File.join(instance_base_directory, "conf", app_name)

  webapp_dir              = File.join(instance_base_directory, "webapps", app_name)

  # If this file doesn't exist, we need to initialize the data directory or
  # re-copy the core schema plugins
  # This lock file must reside under the webapp_dir, so it will be naturally
  # removed if a deployment takes place
  core_schema_plugins_lock_file = File.join(webapp_dir, "core_schema_plugins.lock")

  # Install gems required for geonetwork config manager script
  chef_gem 'xml-simple'
  chef_gem 'equivalent-xml'
  chef_gem 'trollop'

  ruby_block "#{app_name}_initialize_geonetwork_data_directory" do
    block do
      require 'time'

      if Dir.entries(data_dir).size == 2 # Is directory empty?
        # If the data_dir directory is empty, we will copy everything from the
        # origin directory
        data_origin_dir = File.join(webapp_dir, "WEB-INF", "data")
        Chef::Log.info("Copying '#{data_origin_dir}/*' -> '#{data_dir}'")
        FileUtils.cp_r Dir[ "#{data_origin_dir}/*" ], data_dir
      else
        # Copy the defined core schema plugins
        schema_plugins_relative_path = File.join("config", "schema_plugins")
        schema_plugins_origin_dir = File.join(webapp_dir, "WEB-INF", "data", schema_plugins_relative_path)
        schema_plugins_dir = File.join(data_dir, schema_plugins_relative_path)

        if app_parameters['core_schema_plugins']
          core_schema_plugins = app_parameters['core_schema_plugins']
          core_schema_plugins.each do | plugin_name |
            plugin_origin_path = File.join(schema_plugins_origin_dir, plugin_name)
            plugin_destination_path = File.join(schema_plugins_dir, plugin_name)
            Chef::Log.info("Copying '#{plugin_origin_path}' -> '#{plugin_destination_path}'")
            FileUtils.cp_r plugin_origin_path, plugin_destination_path
          end
        end
      end
      Chef::Log.info("Set ownership of '#{data_dir}' to '#{node['tomcat']['user']}:#{node['tomcat']['user']}'")
      FileUtils.chown_R node['tomcat']['user'], node['tomcat']['user'], data_dir

      # Touch this file, so we will not run again unless geonetwork is deployed
      FileUtils.touch core_schema_plugins_lock_file
    end
    only_if {
      ! File.exists?(core_schema_plugins_lock_file) ||
          Dir.entries(data_dir).size == 2
    }
  end

  # Deploy additional schema plugins via Jenkins
  if app_parameters['additional_schema_plugins']
    require 'uri'
    job_name = app_parameters['schema_plugins_build_job']
    schema_plugins = app_parameters['additional_schema_plugins']
    schema_plugins.each do | plugin_name |
      download_url = URI::HTTP.build([nil, node['imos_webapps']['geonetwork']['schema_plugins']['base_url'], nil, "/job/#{job_name}/lastSuccessfulBuild/artifact/#{plugin_name}.gz", nil, nil])

      zip_file_cache_path = File.join("#{Chef::Config[:file_cache_path]}", "#{job_name}.gz")
      remote_file zip_file_cache_path do
        source download_url.to_s
      end

      core_schema_plugins_relative_path = File.join("config", "schema_plugins")
      core_schema_plugins_destination_path = File.join(data_dir, core_schema_plugins_relative_path)

      begin
        tarball zip_file_cache_path do
          destination core_schema_plugins_destination_path
          owner node['tomcat']['user']
          group node['tomcat']['user']
          action :nothing
          subscribes :extract, 'remote_file[zip_file_cache_path]', :immediately
        end
      rescue StandardError => e
        Chef::Log.error("Cannot create schema_plugin directory for #{job_name} due to exception #{e}")
      end
    end
  end

  # log4j override file
  log4j_override_file = File.join(config_dir, "log4j-overrides.cfg")
  logging = app_parameters['logging']

  template log4j_override_file do
    source    "geonetwork/log4j-overrides.cfg.erb"
    owner     node['tomcat']['user']
    group     node['tomcat']['user']
    mode      0644
    notifies  :restart, "service[#{instance_service_name}]", :delayed
    variables ({
      :logging => logging
    })
  end

  if app_parameters['data_bag']
    package 'zip'

    # Download gn-tool.sh from utilities repo
    remote_file node['imos_webapps']['geonetwork']['gn_tool']['binary'] do
      source node['imos_webapps']['geonetwork']['gn_tool']['base_url']
      mode   00755
    end

    # Load given data bag for instance
    geonetwork_data_bag = Chef::DataBagItem.load("geonetwork", app_parameters['data_bag']).to_hash

    gn_admin_username = geonetwork_data_bag['username'] || 'admin'
    gn_admin_password = geonetwork_data_bag['password'] || 'admin'

    import_dir = ::File.join(data_dir, "records")

    gn_tool_import_command = "#{node['imos_webapps']['geonetwork']['gn_tool']['binary']} -o import -l #{import_dir} -g http://localhost:#{instance_port}/#{app_name} -u #{gn_admin_username} -p #{gn_admin_password}"

    if geonetwork_data_bag['git_repo']
      git import_dir do
        repository geonetwork_data_bag['git_repo']
        revision   geonetwork_data_bag['git_branch'] || "master"
        user       geonetwork_data_bag['git_user']   || node['tomcat']['user']
        group      geonetwork_data_bag['git_group']  || node['tomcat']['user']
        action     :sync
      end

      gn_tool_import_command += " -G" # "Intelligent" git import
      gn_tool_export_command = ""
    elsif geonetwork_data_bag['url']
      gn_tool_export_command = "#{node['imos_webapps']['geonetwork']['gn_tool']['binary']} -o export -l #{import_dir} -g #{geonetwork_data_bag['url']}"
    end

    file ::File.join(instance_base_directory, "import-gn-#{app_name}.sh") do
      content "#!/bin/bash
#{gn_tool_export_command}
#{gn_tool_import_command}
"
      user    node['tomcat']['user']
      group   node['tomcat']['user']
      mode    00755
    end
  end

  if app_parameters['config']
    geonetwork_manager_config = ::File.join(instance_base_directory, "geonetwork-config-#{app_name}.json")
    template geonetwork_manager_config do
      source    "geonetwork/geonetwork-config.json.erb"
      owner     node['tomcat']['user']
      group     node['tomcat']['user']
      mode      0644
      variables ({
        :config => app_parameters['config']
      })
    end

    geonetwork_manager_script = ::File.join(instance_base_directory, "geonetwork-config-manager.rb")
    cookbook_file geonetwork_manager_script do
      source "geonetwork/geonetwork-config-manager.rb"
      owner  node['tomcat']['user']
      group  node['tomcat']['user']
      mode   0644
      action :create
    end
  end

end
