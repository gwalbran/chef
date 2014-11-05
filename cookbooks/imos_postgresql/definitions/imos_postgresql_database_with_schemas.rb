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


define :imos_postgresql_database_with_schemas, :cluster => "", :port => nil, :database => nil do

  cluster_name = params[:cluster]
  port = params[:port]


  database_name = params[:database]['database_name'] or
    Chef::Application.fatal!("Required parameter 'database_name' missing")

  database_options = params[:database]['options'] ||
    node[:imos_postgresql][:default_database_options]

  # Create db
  imos_postgresql_general "#{cluster_name}-#{database_name}-database" do
    port      port
    database  "postgres"
    # Take care with postgres irregular key/val quoting
    sql       <<-EOS
      create database #{database_name}
      #{database_options.keys.reduce("") do |acc, key|
        acc += case key.downcase
          when 'template', 'tablespace';
              " #{key}=#{database_options[key]}"
          else
            " #{key}='#{database_options[key]}'"
          end
        end
      };
    EOS
    not_if {
      PostgresqlHelper.query_boolean(port, "postgres",
        <<-EOS
          select exists (select datname from pg_catalog.pg_database where datname = '#{database_name}');
        EOS
      )}
  end


  # Sanity check that the options used at the time to create the database match what we expect
  ruby_block "#{cluster_name}-#{database_name}-sanity-check" do
    block do
      unless PostgresqlHelper.query_boolean(port, database_name,
        <<-EOS
            select
              pg_encoding_to_char(encoding) = '#{database_options['encoding']}'
              and datcollate = '#{database_options['lc_collate']}'
              and datctype = '#{database_options['lc_ctype']}'
              and ts.spcname = '#{database_options['tablespace']}'
            from pg_catalog.pg_database d
            left join pg_catalog.pg_tablespace ts on ts.oid = d.dattablespace
            where datname = '#{database_name}'
        EOS
        )
        Chef::Application.fatal!("Database '#{database_name}' options do not match chef definition")
      end 
    end
  end


  # TODO - haven't implemented grants
  # Define grants against this database
  params[:database]['grants'].each do |database_grant|

    # only useful thing here is the ability to create temporary tables.
    abort( "TODO!" )

    role = database_grant['role'] or
      Chef::Application.fatal!("Required parameter 'role' missing")

    grants = database_grant['grants'] || []
    imos_postgresql_general "#{cluster_name}-#{database_name}-#{role}-grants" do
      port      port
      database  database_name
      sql   <<-EOS
        grant #{grants.join(",")} on database #{database_name} to #{role};
      EOS
    end
  end if params[:database]['grants']


  # Some sql support functions to be installed into the chef schema
  chef_schema_version = 0.2

  ruby_block "#{cluster_name}-#{database_name}-chef-support-sql-funtions" do
    block do
      # some Ruby code
      PostgresqlHelper.query_basic(port, database_name,
        <<-EOS
          -- create supporting schema for common functions
          drop schema if exists chef cascade;
          create schema chef authorization postgres;

          SET search_path = chef, pg_catalog;

          -- versioning, for resource guard - not used yet
          create function version() returns float as
          \\$\\$
          begin
            return ( select #{chef_schema_version} );
          end;
          \\$\\$
          language plpgsql;
          grant all on function chef.version() to public;

          -- for tables, sequences, indexes
          create function objects_missing_acl_aclitem( text, char, aclitem ) returns bool as
          \\$\\$
            declare ret boolean;
            declare schema text := \\$1 ;
            declare kind char := \\$2 ;
            declare acl aclitem := \\$3 ;
            begin
              select coalesce(
                (select bool_or(
                  not coalesce( aclcontains( o.relacl, acl), false )
                )
                from pg_class o
                join pg_namespace n on n.oid=o.relnamespace
                where n.nspname = schema
                and o.relkind = kind
                ), false)
              into ret;
              return ret;
            end
          \\$\\$
          language plpgsql;
          grant all on function objects_missing_acl_aclitem( text, char, aclitem ) to public;

          -- for functions
          create function functions_missing_aclitem( text, aclitem ) returns bool as
          \\$\\$
            declare ret boolean;
            declare schema text := \\$1 ;
            declare acl aclitem := \\$2 ;
            begin
              select coalesce(
                (select bool_or(
                  not coalesce( aclcontains( f.proacl, acl), false )
                )
                from pg_proc f
                join pg_namespace n on n.oid=f.pronamespace
                where n.nspname = schema
                ), false)
              into ret;
              return ret;
            end
          \\$\\$
          language plpgsql;
          grant all on function functions_missing_aclitem( text, aclitem ) to public;

          -- for schemas
          create function schema_missing_aclitem( text, aclitem ) returns bool as
          \\$\\$
            declare ret boolean;
            declare schema text := \\$1 ;
            declare acl aclitem := \\$2 ;
            begin
              select coalesce(
                (select bool_or(
                  not coalesce( aclcontains( n.nspacl, acl), false )
                )
                from pg_namespace n
                where n.nspname = schema
                ), false)
              into ret;
              return ret;
            end
          \\$\\$
          language plpgsql;
          grant all on function schema_missing_aclitem( text, aclitem ) to public;

          -- default privileges tables, sequences indexes and functions
          create function objects_missing_acl_default_aclitem( text, text, char, aclitem ) returns bool as
            \\$\\$
              declare ret boolean;
              declare target_role text := \\$1 ;
              declare schema text := \\$2 ;
              declare kind char := \\$3 ;
              declare acl aclitem := \\$4 ;
              begin
                select coalesce(
                  ( select not coalesce( aclcontains( d.defaclacl, acl), false )
                  from pg_catalog.pg_default_acl d
                  left join pg_catalog.pg_namespace n on n.oid = d.defaclnamespace
                  left join pg_catalog.pg_authid a on a.oid = d.defaclrole
                  where a.rolname = target_role
                  and n.nspname = schema
                  and d.defaclobjtype = kind
                  ), true)
                into ret;
                return ret;
              end
            \\$\\$
          language plpgsql;
          grant all on function objects_missing_acl_default_aclitem( text, text, char, aclitem ) to public;
        EOS
      )
    end
    not_if {
        PostgresqlHelper.query_boolean(port, database_name,
        <<-EOS
          select exists (
            select nspname from pg_namespace where nspname = 'chef'
          )
        EOS
        ) && 
        PostgresqlHelper.query_boolean(port, database_name,
        <<-EOS
          select chef.version() = #{chef_schema_version}
        EOS
      )}
  end

  # Define schemas and associated role permissions on schemas
  params[:database]['schemas'].each do |schema|

    schema_name = schema['name'] or
      Chef::Application.fatal!("Required parameter 'name' missing")

    schema_owner = schema['owner'] || 'postgres'

    resource_prefix = "#{cluster_name}-#{database_name}-#{schema_name}"


    # Define schema
    imos_postgresql_general "#{resource_prefix}-schema" do
      port      port
      database  database_name
      sql       "create schema #{schema_name};"
      not_if {
        PostgresqlHelper.query_boolean(port, database_name,
          <<-EOS
            select exists (
              select nspname from pg_namespace where nspname = '#{schema_name}'
            );
          EOS
        )}
    end


    # Define schema owner
    # Note, that this also applies a 'CU' acl grant behind the scenes.
    imos_postgresql_general "#{resource_prefix}-#{schema_owner}-owner" do
      port      port
      database  database_name
      sql       <<-EOS
          alter schema #{schema_name} owner to \\"#{schema_owner}\\"
        EOS
      not_if {
        PostgresqlHelper.query_boolean(port, database_name,
          <<-EOS
            select exists (
                select nspname
                from pg_namespace s
                left join pg_roles a on a.oid = s.nspowner
                where s.nspname = '#{schema_name}'
                and a.rolname = '#{schema_owner}'
            );
          EOS
        )}
    end

    # Define schema permissions
    schema['permissions'].each do |permission|

      schema_target_role = permission['role'] or
        Chef::Application.fatal!("Required parameter 'role' missing")

      schema_target_acl = schema_target_role == 'public'?'':"\"#{schema_target_role}\""

      # TODO: The provider needs to know the schema owner in order to correctly apply the grant.
      # However the provider could equally use a sql sub-select against table metadata to determine
      # this info. This would simply the code here by eliminating the schema_owner attribute
      case permission['type']
        when 'read' then

          # Schema
          imos_postgresql_general "#{resource_prefix}-#{schema_target_role}-read" do
            port      port
            database  database_name
            sql       <<-EOS
                grant usage on schema #{schema_name} to \\"#{schema_target_role}\\";
              EOS
            only_if {
              PostgresqlHelper.query_boolean(port, database_name, <<-EOS
                  select chef.schema_missing_aclitem( '#{schema_name}', '#{schema_target_acl}=U/\\"#{schema_owner}\\"')
                EOS
            )}
          end

          # Note that to test these objects it's necessary to under another name, and alter ownership, to avoid default privs
          # automatically adding the privilege. Eg.
          # psql -h localhost -U jfca -p 15432 -d harvest -c 'create table aatams_sattag_nrt.mytable ( mycolumn int );\
          #   alter table aatams_sattag_nrt.mytable owner to aatams_sattag_nrt '

          # Tables
          imos_postgresql_general "#{resource_prefix}-#{schema_target_role}-tables-read" do
            port      port
            database  database_name
            sql       <<-EOS
                grant select on all tables in schema #{schema_name} to \\"#{schema_target_role}\\";
              EOS
            only_if {
              PostgresqlHelper.query_boolean(port, database_name,
                <<-EOS
                  select chef.objects_missing_acl_aclitem( '#{schema_name}', 'r', '#{schema_target_acl}=r/\\"#{schema_owner}\\"' )
                    or chef.objects_missing_acl_aclitem( '#{schema_name}', 'v', '#{schema_target_acl}=r/\\"#{schema_owner}\\"' );
                    -- TODO investigate 'i' for indexes?
                EOS
            )}
          end

          # Tables default
          imos_postgresql_general "#{resource_prefix}-#{schema_target_role}-tables-default-read" do
            port      port
            database  database_name
            sql       <<-EOS
                alter default privileges for role \\"#{schema_owner}\\" in schema #{schema_name} grant select on tables to \\"#{schema_target_role}\\"
              EOS
            only_if {
              PostgresqlHelper.query_boolean(port, database_name, <<-EOS
                  select chef.objects_missing_acl_default_aclitem( '#{schema_owner}', '#{schema_name}', 'r', '#{schema_target_acl}=r/\\"#{schema_owner}\\"')
                EOS
            )}
          end

          # Sequences
          imos_postgresql_general "#{resource_prefix}-#{schema_target_role}-seqs-read" do
            port      port
            database  database_name
            sql       <<-EOS
                grant select on all sequences in schema #{schema_name} to \\"#{schema_target_role}\\"
            EOS
            only_if {
              PostgresqlHelper.query_boolean(port, database_name, <<-EOS
                  select chef.objects_missing_acl_aclitem( '#{schema_name}', 'S', '#{schema_target_acl}=r/\\"#{schema_owner}\\"')
                EOS
            )}
          end

          # Sequences default
          imos_postgresql_general "#{resource_prefix}-#{schema_target_role}-seqs-default-read" do
            port      port
            database  database_name
            sql       <<-EOS
                alter default privileges for role \\"#{schema_owner}\\" in schema #{schema_name} grant select on sequences to \\"#{schema_target_role}\\";
              EOS
            only_if {
              PostgresqlHelper.query_boolean(port, database_name, <<-EOS
                  select chef.objects_missing_acl_default_aclitem( '#{schema_owner}', '#{schema_name}', 'S', '#{schema_target_acl}=r/\\"#{schema_owner}\\"')
                EOS
            )}
          end

          # Functions
          imos_postgresql_general "#{resource_prefix}-#{schema_target_role}-functions-execute" do
            port      port
            database  database_name
            sql       <<-EOS
                grant execute on all functions in schema #{schema_name} to \\"#{schema_target_role}\\";
              EOS
            only_if {
              PostgresqlHelper.query_boolean(port, database_name, <<-EOS
                  select chef.functions_missing_aclitem( '#{schema_name}', '#{schema_target_acl}=X/\\"#{schema_owner}\\"')
                EOS
            )}
          end

          # Functions default
          imos_postgresql_general "#{resource_prefix}-#{schema_target_role}-functions-default-execute" do
            port      port
            database  database_name
            sql       <<-EOS
                alter default privileges for role #{schema_owner} in schema #{schema_name} grant execute on functions to \\"#{schema_target_role}\\"
            EOS
            only_if {
              PostgresqlHelper.query_boolean(port, database_name, <<-EOS
                  select chef.objects_missing_acl_default_aclitem( '#{schema_owner}', '#{schema_name}', 'f', '#{schema_target_acl}=X/\\"#{schema_owner}\\"')
                EOS
            )}
          end


        when 'write' then

          # Schema
          imos_postgresql_general "#{resource_prefix}-#{schema_target_role}-read" do
            port      port
            database  database_name
            sql       <<-EOS
                grant all on schema #{schema_name} to \\"#{schema_target_role}\\";
              EOS
            only_if {
              schema_target_role != 'public' and
              PostgresqlHelper.query_boolean(port, database_name, <<-EOS
                  select chef.schema_missing_aclitem( '#{schema_name}', '\\"#{schema_target_role}\\"=UC/\\"#{schema_owner}\\"')
                EOS
            )}
          end

          # Tables
          imos_postgresql_general "#{resource_prefix}-#{schema_target_role}-tables-read" do
            port      port
            database  database_name
            sql       <<-EOS
                grant all on all tables in schema #{schema_name} to \\"#{schema_target_role}\\"
              EOS
            only_if {
              schema_target_role != 'public' and
              PostgresqlHelper.query_boolean(port, database_name,
                <<-EOS
                  select chef.objects_missing_acl_aclitem( '#{schema_name}', 'r', '\\"#{schema_target_role}\\"=arwdDxt/\\"#{schema_owner}\\"' )
                    or chef.objects_missing_acl_aclitem( '#{schema_name}', 'v', '\\"#{schema_target_role}\\"=arwdDxt/\\"#{schema_owner}\\"' );
                    -- TODO investigate 'i' for indexes?
                EOS
            )}
          end

          # Tables default
          imos_postgresql_general "#{resource_prefix}-#{schema_target_role}-tables-default-read" do
            port      port
            database  database_name
            sql       <<-EOS
                alter default privileges for role \\"#{schema_owner}\\" in schema #{schema_name} grant all on tables to \\"#{schema_target_role}\\"
            EOS
            only_if {
              schema_target_role != 'public' and
              PostgresqlHelper.query_boolean(port, database_name, <<-EOS
                  select chef.objects_missing_acl_default_aclitem( '#{schema_owner}', '#{schema_name}', 'r', '\\"#{schema_target_role}\\"=arwdDxt/\\"#{schema_owner}\\"')
                EOS
            )}
          end

          # Sequences
          imos_postgresql_general "#{resource_prefix}-#{schema_target_role}-seqs-read" do
            port      port
            database  database_name
            sql       <<-EOS
                grant all on all sequences in schema #{schema_name} to \\"#{schema_target_role}\\"
            EOS
            only_if {
              schema_target_role != 'public' and
              PostgresqlHelper.query_boolean(port, database_name, <<-EOS
                  select chef.objects_missing_acl_aclitem( '#{schema_name}', 'S', '\\"#{schema_target_role}\\"=rwU/\\"#{schema_owner}\\"')
                EOS
            )}
          end

          # Sequences default
          imos_postgresql_general "#{resource_prefix}-#{schema_target_role}-seqs-default-read" do
            port      port
            database  database_name
            sql       <<-EOS
                alter default privileges for role \\"#{schema_owner}\\" in schema #{schema_name} grant all on sequences to \\"#{schema_target_role}\\"
              EOS
            only_if {
              schema_target_role != 'public' and
              PostgresqlHelper.query_boolean(port, database_name, <<-EOS
                  select chef.objects_missing_acl_default_aclitem( '#{schema_owner}', '#{schema_name}', 'S', '\\"#{schema_target_role}\\"=rwU/\\"#{schema_owner}\\"')
                EOS
            )}
          end

          # Functions
          # 'all' is equivalent to 'execute' for at least 9.1
          imos_postgresql_general "#{resource_prefix}-#{schema_target_role}-functions-execute" do
            port      port
            database  database_name
            sql       <<-EOS
                grant all on all functions in schema #{schema_name} to \\"#{schema_target_role}\\"
              EOS
            only_if {
              schema_target_role != 'public' and
              PostgresqlHelper.query_boolean(port, database_name, <<-EOS
                  select chef.functions_missing_aclitem( '#{schema_name}', '\\"#{schema_target_role}\\"=X/\\"#{schema_owner}\\"')
                EOS
            )}
          end

          # Functions default
          imos_postgresql_general "#{resource_prefix}-#{schema_target_role}-functions-default-execute" do
            port      port
            database  database_name
            sql       <<-EOS
                alter default privileges for role \\"#{schema_owner}\\" in schema #{schema_name} grant all on functions to \\"#{schema_target_role}\\"
              EOS
            only_if {
              schema_target_role != 'public' and
              PostgresqlHelper.query_boolean(port, database_name, <<-EOS
                  select chef.objects_missing_acl_default_aclitem( '#{schema_owner}', '#{schema_name}', 'f', '\\"#{schema_target_role}\\"=X/\\"#{schema_owner}\\"')
                EOS
            )}
          end

        else
          Chef::Application.fatal!("Unrecognized permission type '#{permission['type']}'")
        end

    end if schema['permissions']


    # Define schema extensions
    # Must be after permissions to ensure any created objects inherit any default privileges
    schema['extensions'].each do |extension|

      extension_name = extension['name']

      # Deal with custom extensions available on the cluster
      if params[:custom_extensions].include?("#{cluster_name}-#{extension_name}")

        # Create the extension if it doesn't exist
        # Required because may be specified in database definition after git deployment of the extension code
        ruby_block "#{resource_prefix}-#{extension_name}-custom-extension" do
          block do
            Chef::Log.info("Create custom extension '#{extension_name}' from files in schema '#{schema_name}' for database '#{database_name}'")

            PostgresqlHelper.query_basic(port, database_name,
              <<-EOS
                -- perhaps should use recreate extension
                drop extension if exists \\"#{extension_name}\\";
                create extension \\"#{extension_name}\\" schema #{schema_name};
              EOS
            )
          end
          not_if {
              PostgresqlHelper.query_boolean(port, database_name,
              <<-EOS
                select exists (select extname, nspname from pg_catalog.pg_extension, pg_catalog.pg_namespace
                  where pg_namespace.oid = extnamespace
                  and extname = '#{extension_name}'
                  and nspname= '#{schema_name}' );
              EOS
            )}
        end

        # Update, in response to a change to the git head
        ruby_block "#{resource_prefix}-#{extension_name}-custom-extension-reload-from-repo" do
          block do
            Chef::Log.info("Updating custom extension '#{extension_name}' from files in schema '#{schema_name}' for database '#{database_name}'")

            PostgresqlHelper.query_basic(port, database_name,
              <<-EOS
                -- Perhaps should be using recreate extension
                drop extension if exists \\"#{extension_name}\\";
                create extension \\"#{extension_name}\\" schema #{schema_name};
              EOS
            )
          end
          action :nothing
          subscribes :create, "ruby_block[link-extension-#{cluster_name}-#{extension_name}]"
        end

      else

        # A 'normal' extension, where the extension code is already available
        ruby_block "#{resource_prefix}-#{extension_name}-normal-extension" do
          block do
            Chef::Log.info("Create normal extension '#{extension_name}'")
            PostgresqlHelper.query_basic(port, database_name,
              <<-EOS
                create extension \\"#{extension_name}\\" schema #{schema_name};
              EOS
            )
          end
          not_if {
              PostgresqlHelper.query_boolean(port, database_name,
              <<-EOS
                select exists (select extname, nspname from pg_catalog.pg_extension, pg_catalog.pg_namespace
                  where pg_namespace.oid = extnamespace
                  and extname = '#{extension_name}'
                  and nspname = '#{schema_name}' );
              EOS
            )}
        end
      end

    end if schema['extensions']
  end if params[:database]['schemas']
end

