default[:imos_postgresql][:postgresql_databases_data_bag] = 'postgresql_databases'
default[:imos_postgresql][:postgresql_roles_data_bag]     = 'postgresql_roles'
default[:imos_postgresql][:default_role_connection_limit] = 5
default[:imos_postgresql][:default_cluster_name] = "main"
default[:imos_postgresql][:postgresql_version_precise] = "9.3"
default[:imos_postgresql][:postgis_version_precise] = "2.1"
default[:imos_postgresql][:postgresql_version] = "9.6"
default[:imos_postgresql][:postgis_version] = "2.3"
default[:imos_postgresql][:postgresql_service_user] = "postgres"
default[:imos_postgresql][:postgresql_service_group] = "postgres"
default[:imos_postgresql][:postgresql_configure_user] = "postgres"
default[:imos_postgresql][:postgresql_service_user_home] = "/var/lib/postgresql"

default[:imos_postgresql][:config] = {
  'listen_addresses' => 'localhost',
  'port' => 5432,
  'max_connections' => 100,
  'shared_buffers' => '24MB',
  'log_line_prefix' => '%t %h %u %d %p %e',
  'datestyle' => 'iso, mdy',
  'default_text_search_config' => 'pg_catalog.english',
  'ssl' => true
}

default[:imos_postgresql][:hba] = [
  {:type => 'hostssl', :db => 'all', :user => 'postgres', :addr => '0.0.0.0/0', :method => 'reject' },
  {:type => 'local', :db => 'all', :user => 'postgres', :addr => nil, :method => 'peer'},
  {:type => 'hostssl', :db => 'all', :user => 'all', :addr => '0.0.0.0/0', :method => 'md5'},
]

default[:imos_postgresql][:default_database_options] = {
  'template' => 'template0',
  'tablespace' => 'pg_default',
  'encoding' => 'UTF8',
  'lc_collate' => 'en_AU.UTF-8',
  'lc_ctype' => 'en_AU.UTF-8'
}
