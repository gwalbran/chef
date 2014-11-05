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


define :imos_postgresql_roles, :cluster => "", :port => nil, :roles => [], :default_role_connection_limit => nil do

  cluster = params[:cluster]
  port = params[:port]
  roles = params[:roles]


  roles.each() do |role|

    name = role['name'] or
      Chef::Application.fatal!("Required parameter 'name' missing")


    # Create the role
    imos_postgresql_general "#{cluster}-#{name}-role" do
      port      port
      database  "postgres"
      sql       <<-EOS
          create role \\"#{name}\\"
        EOS
      not_if {
        PostgresqlHelper.query_boolean(port, "postgres",
          <<-EOS
            select exists (select * from pg_catalog.pg_roles where rolname = '#{name}');
          EOS
        )}
    end


    # Set password
    password = role['password']
    if password
      password = PasswordHelper.compute_password(name, password)

      imos_postgresql_general "#{cluster}-#{name}-passwd" do
        port      port
        database  "postgres"
        sql       <<-EOS
            alter role \\"#{name}\\" password '#{password}'
          EOS
        msg       "alter role #{name} password;"
        not_if {
          PostgresqlHelper.query_boolean(port, "postgres",
            <<-EOS
              select exists (select * from pg_catalog.pg_authid
                where rolname = '#{name}'
                and rolpassword = '#{password}');
            EOS
          )}
      end
    else
      imos_postgresql_general "#{cluster}-#{name}-passwd" do
        port      port
        database  "postgres"
        sql       <<-EOS
            alter role \\"#{name}\\" password null
          EOS
        msg       "alter role #{name} password;"
        not_if {
          PostgresqlHelper.query_boolean(port, "postgres",
            <<-EOS
              select exists (select * from pg_catalog.pg_authid
                where rolname = '#{name}'
                and rolpassword is null);
            EOS
          )}
      end
    end


    # Establish membership
    role_membership = role['memberof'] || []
    role_membership.each() do |member|
      imos_postgresql_general "#{cluster}-#{name}-#{member}-member" do
        port      port
        database  "postgres"
        sql       <<-EOS
            grant \\"#{member}\\" to \\"#{name}\\"
          EOS
        not_if {
          PostgresqlHelper.query_boolean(port, "postgres",
            <<-EOS
              select exists (
                select *
                from pg_auth_members m
                left join pg_roles x on m.roleid = x.oid
                left join pg_roles y on m.member = y.oid
                where x.rolname = '#{member}'
                and y.rolname = '#{name}'
              );
            EOS
          )}
      end
    end


    # Role defaults are mostly the same for both users and groups, user gets login
    rolsuper = false
    rolcreatedb = false
    rolcanlogin = true
    rolreplication = false
    rolinherit = true
    rolconnlimit = role['connection_limit'] || params[:default_role_connection_limit]

    # Overide with standard named grants
    privileges = role['privileges'] || []
    privileges.each() do |privilege|
      case privilege.downcase
        when "superuser"; rolsuper = true
        when "nosuperuser"; rolsuper = false
        when "createdb"; rolcreatedb = true
        when "nocreatedb"; rolcreatedb = false
        when "login"; rolcanlogin = true
        when "nologin"; rolcanlogin = false
        when "replication"; rolreplication = true
        when "noreplication"; rolreplication = false
        when "inherit"; rolinherit = true
        when "noinherit"; rolinherit = false
        else
          Chef::Application.fatal!("unrecognized option #{privilege}")
        end
    end

    # pg_authid is the same as pg_roles but with unshadowed passwords (like pg_shadow)
    imos_postgresql_general "#{cluster}-#{name}-role-privs" do
      port      port
      database  "postgres"
      sql <<-EOS
        alter role \\"#{name}\\" #{rolsuper ? 'superuser' : 'nosuperuser'};
        alter role \\"#{name}\\" #{rolcreatedb ? 'createdb' : 'nocreatedb'};
        alter role \\"#{name}\\" #{rolcanlogin ? 'login' : 'nologin'};
        alter role \\"#{name}\\" #{rolreplication ? 'replication' : 'noreplication'};
        alter role \\"#{name}\\" #{rolinherit ? 'inherit' : 'noinherit'};
        alter role \\"#{name}\\" connection limit #{rolconnlimit};
      EOS
      not_if {
        PostgresqlHelper.query_boolean(port, "postgres",
          <<-EOS
            select exists (select * from pg_catalog.pg_authid
            where rolname = '#{name}'
            and rolsuper = #{rolsuper}
            and rolcreatedb = #{rolcreatedb}
            and rolcanlogin = #{rolcanlogin}
            and rolreplication = #{rolreplication}
            and rolinherit = #{rolinherit}
            and rolconnlimit = #{rolconnlimit}
            ) ;
          EOS
        )}
    end


    # setconfig parameters
    role['setconfig'].each() do |setconfig|

      database = setconfig['database']
      key = setconfig['key'] or Chef::Application.fatal!("Setconfig key missing for role '#{name}'")
      value = setconfig['value'] or Chef::Application.fatal!("Setconfig value missing for role '#{name}'")

      # Alter the setconfig for the role
      imos_postgresql_general "#{cluster}-#{name}-#{database}-#{key}-#{value}-setconfig" do
        port      port
        database  database || "postgres"
        sql       <<-EOS
            alter role \\"#{name}\\" set #{key} to #{value}
          EOS
        not_if {
          PostgresqlHelper.query_boolean(port, "postgres",
            <<-EOS
              select coalesce(
              (select s.setconfig @> array['#{key}=#{value}']
              from pg_db_role_setting s
              left join pg_authid r ON s.setrole = r.oid
              left join pg_database d ON s.setdatabase = d.oid
              where d.datname #{database ? " = #{database}": " is null"}
              and r.rolname = '#{name}')
              , false)
            EOS
          )}
      end
    end if role['setconfig']

  end
end

