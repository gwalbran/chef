#
# Cookbook Name:: imos_webapps
# Definition:: ramadda
#
# Copyright 2012, IMOS
#
# All rights reserved - Do Not Redistribute
#

define :ramadda do

  app_parameters          = params[:app_parameters]
  instance_parameters     = params[:instance_parameters]
  instance_service_name   = params[:instance_service_name]
  instance_base_directory = params[:instance_base_directory]

  instance_vhost          = instance_parameters['vhost']
  data_dir                = app_parameters['data_dir']
  app_name                = app_parameters['name']

  # TODO DF: This recipe does not take care of MySQL DB creation for Ramadda.
  # The MySQL snippet below is probably quite obsolete, not written by me and was
  # taken from the ramamdda cookbook. See more below.

  directory data_dir do
    owner  node['tomcat']['user']
    group  node['tomcat']['user']
    mode   0755
    action :create
  end

  directory File.join(data_dir, "plugins") do
    owner  node['tomcat']['user']
    group  node['tomcat']['user']
    mode   0755
    action :create
  end

  # Config file has to go to a different place, this is why we don't use the
  # proper way of embedding configuration
  ramadda_jndi = Chef::EncryptedDataBagItem.load('jndi_resources', 'ramadda').to_hash
  template File.join(data_dir, "repository.properties") do
    source    "ramadda/repository.properties.erb"
    owner     node['tomcat']['user']
    group     node['tomcat']['user']
    mode      0644
    variables ({:jndi => ramadda_jndi})
  end

  # Fetch all plugins first so they're ready when the war drops and tomcat restarts
  all_plugins_jar_path = File.join(data_dir, "plugins/allplugins.jar")
  ruby_block "fetch_ramadda_all_plugins_jar" do
    block do
      # The imos artifact fetcher depends on these libs but can't be parsed until they are installed
      require 'rubygems'
      require 'json'
      require 'net/http'

      artifact_manifest = Chef::EncryptedDataBagItem.load("imos_artifacts", "ramadda-all-plugins")
      fetcher = ArtifactFetcher.new
      cache_jar_path, artifact_downloaded = fetcher.fetch_artifact(artifact_manifest, node)

      # Now move the jar file into position
      if !::File.exists?(all_plugins_jar_path) || ::File.mtime(all_plugins_jar_path) < ::File.mtime(cache_jar_path)
        FileUtils.cp cache_jar_path, all_plugins_jar_path
      end
    end
  end

  # Ensure the tomcat user owns the allplugins.jar
  execute "chown tomcat #{all_plugins_jar_path}" do
    command "chown #{node["tomcat"]["user"]}:#{node["tomcat"]["user"]} #{all_plugins_jar_path}"
    action :run
  end

end

#####################
# MYSQL FOR RAMADDA #
#####################

# Prevent problems, just don't use this stuff, this is why it's commented!
# I was promised around Aug 2012 that this will be decommissioned, still
# waiting...
#
#include_recipe "mysql::server"
#include_recipe "mysql::ruby"
#include_recipe "database::mysql"
#include_recipe "ramadda::passwords"
#
#node.set['mysql']['bind_address'] = 'localhost'
#node.set[:ramadda][:mysql][:host] = node['mysql']['bind_address']
#
#mysql_connection_info = {
#  :host => "localhost",
#  :username => 'root',
#  :password => node['mysql']['server_root_password']
#}
#
## Create the database
#mysql_database node[:ramadda][:mysql][:database] do
#  connection mysql_connection_info
#  action :create
#end
#
## Create the user and grant all privileges
#mysql_database_user ramadda_jndi['username'] do
#  connection mysql_connection_info
#  password ramadda_jndi['password']
#  database_name 'repository'
#  host node['mysql']['bind_address']
#  action :grant
#end
#
#mysql_database "flush mysql privileges" do
#  connection mysql_connection_info
#  sql "flush privileges"
#  action :query
#end

