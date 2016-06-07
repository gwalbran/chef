#
# Cookbook Name:: imos_postgresql
# Recipe:: schema_support
#
# Copyright 2013, IMOS
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0c
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Repositories
apt_repository 'official_postgres' do
  uri 'http://apt.postgresql.org/pub/repos/apt/'
  distribution "#{node['lsb']['codename']}-pgdg"
  components ['main']
  key 'https://www.postgresql.org/media/keys/ACCC4CF8.asc'
end

# Other Packages
node['postgresql']['packages'].each do |pg_pack|
  package pg_pack
end if node['postgresql']['packages']

# Install package now, so postgres user is created
package 'postgresql-common'

# Support for replication connections
if node['postgresql']['known_hosts']

    # Deploy the private key
    postgres_ssh_key = Chef::EncryptedDataBagItem.load("users", node[:imos_postgresql][:postgresql_service_user])['ssh_priv_key']
    if postgres_ssh_key
      file "#{node[:imos_postgresql][:postgresql_service_user_home]}/.ssh/id_rsa" do
        content   postgres_ssh_key
        owner     node[:imos_postgresql][:postgresql_service_user]
        group     node[:imos_postgresql][:postgresql_service_group]
        mode      00400
      end
    end

    # TODO - Couldn't get this working in vagrant, for localhost, since not enough of the networking configuration is mocked
    #
    # known_hosts_tuples   = []
    #
    # # All the backup nodes
    # all_nodes = search(:node, "fqdn:*")
    #
    # # Iterate on all nodes, configure a pulling rsync backup for them
    # all_nodes.each do |n|
    #   host_name = n['fqdn'].downcase
    # if n.contains node['postgresql']['known_hosts'] && ...
    #   if n['keys'] && n['keys']['ssh'] && n['keys']['ssh']['host_rsa_public']
    #     ipaddress = n['network']['public_ipv4']
    #     known_hosts_tuples.push([ ipaddress, host_name, n['keys']['ssh']['host_rsa_public'] ])
    #   end
    # end
    #
    # # Add all host keys to known hosts
    # template "#{node[:imos_postgresql][:postgresql_service_user]}/.ssh/known_hosts" do
    #   source "known_hosts.erb"
    #   cookbook "imos_backup"
    #   owner  "#{node[:backup][:username]}"
    #   group  "#{node[:backup][:group]}"
    #   mode   0644
    #   variables(:items => known_hosts_tuples.sort!)
    # end

    # HACK for the moment
    known_hosts="#{node[:imos_postgresql][:postgresql_service_user_home]}/.ssh/known_hosts"

    node['postgresql']['known_hosts'].each do |host|
      execute "known-hosts-#{host}" do
        command <<-EOS
          ssh-keyscan -H #{host} >> #{known_hosts} 2>&1
        EOS
        not_if {
          File.exist?(known_hosts) and
            File.open(known_hosts) { |file| file.grep(/#{host}/) }.any?
        }
      end
    end
end

# Directories
node['postgresql']['directories'].each do |dir|
  # substitute attributes
  dir = eval( %{"#{dir}"} )
  directory dir do
    recursive true
    owner     node[:imos_postgresql][:postgresql_service_user]
    group     node[:imos_postgresql][:postgresql_service_group]
    mode      0755
  end
end if node['postgresql']['directories']

# set the configure role that will create db objects
PostgresqlHelper.set_configure_user(node[:imos_postgresql][:postgresql_configure_user])

database_backups = []

if node['postgresql'] && node['postgresql']['clusters']

  node['postgresql']['clusters'].each do |cluster|


    # determine postgres version required by cluster
    postgresql_version = cluster['postgresql_version'] || node[:imos_postgresql][:postgresql_version]
    postgis_version = cluster['postgis_version'] || node[:imos_postgresql][:postgis_version]

    # install postgres
    # TODO refactor package deployment into the imos_postgresql_cluster definition
    package "postgresql-#{postgresql_version}-postgis-#{postgis_version}"


    cluster_name = cluster['name'] || node[:imos_postgresql][:default_cluster_name]


    # Take default cluster config
    cluster_config = {}
    node[:imos_postgresql][:config].each() { |key,val| cluster_config[key] = val }

    # Overide for this cluster instance in the node
    cluster['config'].each() do |key,val|
      cluster_config[key] = val
    end if cluster['config']

    # apply non production limits for VMs
    if Chef::Config[:dev]
      cluster_config['max_connections'] = node[:imos_postgresql][:config]['max_connections']
      cluster_config['shared_buffers'] = node[:imos_postgresql][:config]['shared_buffers']
    end


    # Create the cluster
    imos_postgresql_cluster cluster_name do
      version     postgresql_version
      config      cluster_config
      hba         cluster['hba'] || node[:imos_postgresql][:hba]
      recovery    cluster['recovery']
      basebackup  cluster['basebackup']
    end


    # Record of custom extensions managed by a repository
    custom_extensions = []

    cluster['git_extension_support'].each do |src|

      extension_name = "#{cluster_name}-#{src.name}"
      custom_extensions << extension_name

      # Clone directory for extension code specific for each cluster instance
      git_extensions_dir = "#{Chef::Config[:file_cache_path]}/postgresql_extension_support/#{extension_name}/"

      directory git_extensions_dir do
        recursive true
      end

      git "deploy-extension-#{extension_name}" do
        repository  src.repository
        revision    src['branch'] || "master"
        action      :sync
        destination git_extensions_dir
      end


      # The extension resource linking name must be predictable as well as unique across clusters so that
      # we can subscribe to events to update extension code
      ruby_block "link-extension-#{extension_name}" do
        block do
          # We can't rely on pg_config output to be correct in a multi-cluster version
          # environment so build dir manually
          pg_ext_dir = "/usr/share/postgresql/#{postgresql_version}/extension/"
          Chef::Application.fatal!("Postgresql extensions directory not found") unless $?.to_i == 0
          files = Dir.glob("#{git_extensions_dir}/extension/*")
          files.each do |src|
            dst = ::File.join(pg_ext_dir, ::File.basename(src))
            if ::File.exist?(dst)
              ::File.delete(dst)
            end
            Chef::Log.info("Linking posgresql extension files '#{src}' -> '#{dst}'")
            ::File.symlink(src, dst)
          end
        end
        # Immediately, so that sql extension code is always available to subsequent extension provisioning steps
        # in the case when don't rely on event-propagation (eg. databag was updated to specify extension use)
        action :nothing
        subscribes :create, "git[deploy-extension-#{extension_name}]", :immediately
      end
    end if cluster['git_extension_support']


    all_role_names = {}
    server_role_passwords = {}

    all_roles = []
    all_databases = []

    # Create the roles
    cluster['roles'].each do |roles_data_bag_name|

      # Load the roles databag
      roles = Chef::EncryptedDataBagItem.load(
        node[:imos_postgresql][:postgresql_roles_data_bag],
        roles_data_bag_name
      )

      # Sanity check duplicate role definitions across databags
      # and record possible password
      roles['roles'].each do |role|
        name = role['name']
        Chef::Application.fatal!("Role '#{name}' already defined") if all_role_names.include? name
        all_role_names[name] = true
        server_role_passwords[name] = role['password']
      end

      all_roles.concat(roles['roles'])
    end if cluster['roles']

    # Define the databases
    cluster['databases'].each do |database_data_bag_name|

      # Load the database databag
      database_data_bag = Chef::EncryptedDataBagItem.load(
         node[:imos_postgresql][:postgresql_databases_data_bag],
         database_data_bag_name
      )

      # If backup user specified then add database to backups
      backup_user = database_data_bag['backup_user']
      if backup_user
        database_backups << {
          'database_name' => database_data_bag['database_name'],
          'username' => backup_user,
          'password' => server_role_passwords[backup_user],
          'host'     => 'localhost',
          'port'     => cluster_config['port']
        }
      end
      all_databases.push(database_data_bag.to_hash)
    end if cluster['databases']

    # Create Roles
    modified_roles = PostgresqlHelper.modified_roles(cluster_name, all_roles)
    deleted_roles = PostgresqlHelper.deleted_roles(cluster_name, all_roles)
    Chef::Log.info("Need to modify #{modified_roles.length} roles in cluster '#{cluster_name}'")
    Chef::Log.debug("Modified roles: '#{modified_roles}'")
    Chef::Log.info("Need to delete #{deleted_roles.length} roles in cluster '#{cluster_name}'") # TODO Handle deletions
    Chef::Log.debug("Deleted roles: '#{deleted_roles}'")

    imos_postgresql_roles "#{cluster_name}-roles" do
      cluster                       cluster_name
      port                          cluster_config['port']
      roles                         modified_roles
      default_role_connection_limit node[:imos_postgresql][:default_role_connection_limit]
    end

    ruby_block "roles_#{cluster_name}" do
      block do
        PostgresqlHelper.save_roles_state(cluster_name, all_roles)
      end
    end

    # Create tablespaces
    Chef::Log.debug("All tablespaces: #{cluster['tablespaces']}")
    cluster['tablespaces'].each do |tablespace|
      Chef::Log.info("Processing tablespace: #{tablespace}")
      imos_postgresql_tablespace tablespace['name'] do
        cluster           cluster_name
        port              cluster_config['port']
        tablespace_name   tablespace['tablespace_name']
        directory         tablespace['directory']
      end
    end if cluster['tablespaces']

    # Create databases
    modified_databases = PostgresqlHelper.modified_databases(cluster_name, all_databases)
    deleted_databases = PostgresqlHelper.deleted_databases(cluster_name, all_databases)
    Chef::Log.info("Need to modify #{modified_databases.length} databases in cluster '#{cluster_name}'")
    Chef::Log.debug("Modified databases: '#{modified_databases}'")
    Chef::Log.info("Need to delete #{deleted_databases.length} databases in cluster '#{cluster_name}'") # TODO Handle deletions
    Chef::Log.debug("Deleted databases: '#{deleted_databases}'")

    modified_databases.each do |database|
      imos_postgresql_database_with_schemas database['database_name'] do
        cluster           cluster_name
        port              cluster_config['port']
        database          database
        custom_extensions custom_extensions
      end
    end

    ruby_block "databases_#{cluster_name}" do
      block do
        PostgresqlHelper.save_databases_state(cluster_name, all_databases)
      end
    end

  end
end


# Process backups
if database_backups.any? &&
    (node.run_list.include?("role[backup]") || node.run_list.include?("role[restore]"))
  backup "pgsql" do
    cookbook "imos_backup"
    template "pgsql"
    params ({ :databases => database_backups })
  end
else
  Chef::Log.warn("No databases for backup")
end

# Patch init service, it needs to create /var/run/postgresl:
# http://www.postgresql.org/message-id/20140530170558.GA5510@behemoth
cookbook_file '/etc/init.d/postgresql' do
  source 'postgresql_init_d'
  owner  'root'
  group  'root'
  mode   00755
end

service "postgresql" do
  service_name "postgresql"
  supports :status => true, :restart => true
  action [:start, :enable]
end
