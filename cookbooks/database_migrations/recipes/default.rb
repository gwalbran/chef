#
# Cookbook Name:: imos_postgresql
# Recipe:: migration
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#
# A recipe for running liquibase migrations, driven by data bag configuration.


base_dir = node['database_migrations']['base_dir']
user = 'root' # TODO: change to node['database_migrations']['user'] when one exists.
group = 'root' # TODO: change to node['database_migrations']['group'] when one exists.

liquibase_dir = ::File.join(base_dir, 'liquibase')
remote_directory liquibase_dir do
  files_backup 0
  purge true
  user user
  group group
end

file ::File.join(liquibase_dir, 'gradlew') do
  mode '0755'
end

changelog_working_dir = ::File.join(base_dir, 'changelogs')
directory changelog_working_dir do
  user user
  group group
end

bin_dir = ::File.join(base_dir, 'bin')
directory bin_dir do
  user user
  group group
end

node['database_migrations']['migrations'].each do |migration|

  migration_databag = Chef::EncryptedDataBagItem.load('database_migrations', migration)
  migration_source_dir = ::File.join(changelog_working_dir, migration)

  git migration do
    repository migration_databag['source']
    destination migration_source_dir
    depth 1
    user user
    group group
  end

  jndi_resource_databag = Chef::EncryptedDataBagItem.load('jndi_resources', migration_databag['jndi_resource'])

  template ::File.join(bin_dir, "run_#{migration}_migration.sh") do
    source "run_migration.sh.erb"
    owner user
    group group
    mode '0755'

    variables(
      :liquibase_dir => liquibase_dir,
      :changelog_file => ::File.join(migration_source_dir, migration_databag['changelog']),
      :default_schema_name => migration_databag['default_schema_name'],
      :jdbc_url => jndi_resource_databag['url'],
      :username => jndi_resource_databag['username'],
      :password => jndi_resource_databag['password']
    )

  end
end
