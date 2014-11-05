#
# Cookbook Name:: nagios
# Recipe:: imos_client_postgresql
#
# Copyright 2013, IMOS
#
# This recipe defines all the NRPE monitors for postgresql
#

# Check for pgsql
# The recipe 'postgresql::server' will set ['postgresql']['password'], it's a
# bit "hacky" to probe for that - but oh well. The proper solution is to have
# the 'postgresql::server' recipe in a role or node definition
if node['postgresql'] && node['postgresql']['password']
  # Check the 'template1' database
  nagios_nrpecheck "check_pgsql_" do
    command "sudo -u postgres #{node['nagios']['plugin_dir']}/check_pgsql"
    action :add
  end

  # check_pgsql will need sudo access as user postgres to check 'template1'
  sudo "nagios_postgres" do
    user node['nagios']['user']
    runas "postgres"
    commands [ "#{node['nagios']['plugin_dir']}/check_pgsql" ]
    host "ALL"
    nopasswd true
  end

  # Port for pgsql
  if node['postgresql']['config'] && node['postgresql']['config']['port']
    pgsql_port = node['postgresql']['config']['port'] || 5432
  end

  # Get databases data bags and iterate on them
  if node['postgresql']['databases']
    node['postgresql']['databases'].each do |data_bag_name|

      # Data bag name is 'postgresql', but should be #{node[:imos_postgresql][:postgresql_data_bag]}
      database_data_bag = Chef::EncryptedDataBagItem.load('postgresql_databases', data_bag_name)

      if database_data_bag['acl'] and database_data_bag['acl'].first

        # Get the data bag of the owner of the database
        user_data_bag_name = database_data_bag['acl'].first['username'] or
          Chef::Application.fatal!("Could not obtain database owner data bag name for database in data bag '#{data_bag_name}'")

        user_data_bag = Chef::EncryptedDataBagItem.load('postgresql_users', user_data_bag_name).to_hash

        # Database owner username
        database_owner_username = user_data_bag['id'] or
          Chef::Application.fatal!("Could not obtain database owner username for database in data bag '#{database_owner_username}'")

        # Database owner password
        database_owner_password = user_data_bag['password'] or
          Chef::Application.fatal!("Could not obtain database owner password for database in data bag '#{database_owner_username}'")

        # Database name
        database_name           = database_data_bag['database_name'] or
          Chef::Application.fatal!("Could not obtain database owner password for database in data bag '#{data_bag_name}'")

        # Check the #{database_name} database
        nagios_nrpecheck "check_pgsql_#{data_bag_name}" do
          command "#{node['nagios']['plugin_dir']}/check_pgsql \
-H localhost -P #{pgsql_port} -d #{database_name} \
-l #{database_owner_username} -p #{database_owner_password}"
          action :add
        end
      end
    end
  end
end


