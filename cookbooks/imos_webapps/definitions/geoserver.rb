#
# Cookbook Name:: imos_webapps
# Definition:: geoserver
#
# Copyright 2012, IMOS
#
# All rights reserved - Do Not Redistribute
#

define :geoserver do
  include_recipe "imos_core::xml_tools"

  app_parameters          = params[:app_parameters]
  instance_parameters     = params[:instance_parameters]
  instance_service_name   = params[:instance_service_name]
  instance_base_directory = params[:instance_base_directory]

  instance_vhost          = instance_parameters['vhost']
  app_name                = app_parameters['name']
  data_dir                = app_parameters['data_dir'] \
    || Chef::Application.fatal!("'data_dir' attribute must be defined for geoserver!")

  # Initialize data directory (must happen before git repo clone)
  directory data_dir do
    owner     node['tomcat']['user']
    group     node['tomcat']['user']
    mode      0755
    recursive true
  end

  package 'libnetcdf-dev' # Required by the gogoduck plugin

  geoserver_username = Chef::EncryptedDataBagItem.load('passwords', 'geoserver')['username']
  geoserver_password = Chef::EncryptedDataBagItem.load('passwords', 'geoserver')['password']

  protocol = app_parameters['https'] ? "https" : "http"
  geoserver_url = "#{protocol}://#{instance_vhost}/#{app_name}"

  if app_parameters['data_bag']
    # Load given data bag for instance
    geoserver_data_bag = Chef::DataBagItem.load("geoserver", app_parameters['data_bag']).to_hash

    git_depth = geoserver_data_bag['git_deep_clone'] ? nil : 1

    git data_dir do
      repository geoserver_data_bag['git_repo']   || "https://github.com/aodn/geoserver-config.git"
      revision   geoserver_data_bag['git_branch'] || "master"
      depth      git_depth
      action     :sync
      notifies   :create, "ruby_block[#{data_dir}_geoserver_injected_variables]", :immediately
      user       geoserver_data_bag['git_user']   || node['tomcat']['user']
      group      geoserver_data_bag['git_group']  || node['tomcat']['user']
    end

    # Inject proxyBaseUrl to global.xml at /global/settings/proxyBaseUrl
    geoserver_injected_variables = []
    geoserver_injected_variables << [ "global.xml", "/global/settings/proxyBaseUrl", geoserver_url ]
    if app_parameters['injected_variables']
      geoserver_injected_variables.concat(app_parameters['injected_variables'].dup)
    end

    ruby_block "#{data_dir}_geoserver_injected_variables" do
      block do
        geoserver_injected_variables.each do |var_tuple|
          file, xpath, value = var_tuple
          file = ::File.join(data_dir, file)
          Chef::Log.info "Injecting geoserver variable in '#{file}', '#{xpath}' => '#{value}'"
          Chef::Recipe::XMLHelper.insert_xml_node(file, xpath, value)
        end
      end
      only_if {
        # Test if anything needs changing, so the next block can restart
        # geoserver only if required
        need_change = false
        geoserver_injected_variables.each do |var_tuple|
          file, xpath, value = var_tuple
          file = ::File.join(data_dir, file)
          current_var_value = Chef::Recipe::XMLHelper.get_xml_value(file, "#{xpath}")
          Chef::Log.info "Current value of injected geoserver variable in '#{file}', '#{xpath}' => '#{current_var_value}'"
          if ! current_var_value || current_var_value.to_s != value.to_s
            Chef::Log.info "Injecting new variable value in '#{file}', '#{xpath}' => '#{value}' (was '#{current_var_value}')"
            need_change = true
          end
        end
        need_change
      }
      notifies :restart, "service[#{instance_service_name}]", :delayed
    end

    # Use geoserver username/password from given data bag if available
    geoserver_username = geoserver_data_bag['username'] || geoserver_username
    geoserver_password = geoserver_data_bag['password'] || geoserver_password
  else
    Chef::Log.warn("Not cloning any git repository for geoserver '#{instance_service_name}'")
  end

  template ::File.join(data_dir, "security", "usergroup", "default", "users.xml") do
    source    "geoserver/users.xml.erb"
    owner     node['tomcat']['user']
    group     node['tomcat']['user']
    mode      0644
    notifies  :restart, "service[#{instance_service_name}]", :delayed
    variables ({
      :username => geoserver_username,
      :password => geoserver_password
    })
  end

  if app_parameters['config_ftl']
    config_ftl = nil

    if app_parameters['config_ftl']['data_bag']
      Chef::Log.info "Getting config.ftl config from data bag '#{app_parameters['config_ftl']['data_bag']}'"
      config_ftl.nil? and config_ftl = {}
      config_ftl_data_bag =
        Chef::EncryptedDataBagItem.load('imos_webapps_geoserver_config_ftl', app_parameters['config_ftl']['data_bag'])
      config_ftl.merge!(config_ftl_data_bag.to_hash.dup['values'])
    end

    if app_parameters['config_ftl']['overrides']
      Chef::Log.info "Overriding config.ftl config: '#{app_parameters['config_ftl']['overrides']}'"
      config_ftl.nil? and config_ftl = {}
      config_ftl.merge!(app_parameters['config_ftl']['overrides'])
    end

    # Define baseurl, only if there isn't anything else defined
    if ! config_ftl.nil? && ! config_ftl['baseurl']
      Chef::Log.info "Adding config.ftl baseurl: '#{geoserver_url}'"
      config_ftl['baseurl'] = geoserver_url
    end

    # Configure config.ftl only if there's anything to do
    if ! config_ftl.nil?
      template ::File.join(data_dir, "workspaces", "config.ftl") do
        source    "geoserver/config.ftl.erb"
        owner     node['tomcat']['user']
        group     node['tomcat']['user']
        mode      0644
        notifies  :restart, "service[#{instance_service_name}]", :delayed
        variables ({
          :config => config_ftl
        })
      end
    end
  end
end
