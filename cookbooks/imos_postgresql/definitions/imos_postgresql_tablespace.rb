#
# Cookbook Name:: imos_postgresql
# Recipe:: official_postgres
#
# Copyright 2016, IMOS
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


define :imos_postgresql_tablespace, :cluster => "", :port => nil, :tablespace_name => nil, :directory => nil do

  cluster_name = params[:cluster]
  port = params[:port]

  tablespace_name = params[:tablespace_name] or
    Chef::Application.fatal!("Required parameter 'tablespace_name' missing")

  directory = params[:directory] or
    Chef::Application.fatal!("Required parameter 'directory' missing")

  # Create tablespace
  imos_postgresql_general "#{cluster_name}-#{tablespace_name}-tablespace" do
    port      port
    database  "postgres"
    sql       <<-EOS
      create tablespace #{tablespace_name} location '#{directory}';
    EOS
    Chef::Log.info("Creating tablespace '#{tablespace_name}' in directory '#{directory}'")
    not_if {
      PostgresqlHelper.query_boolean(port, "postgres",
        <<-EOS
          select exists (select spcname from pg_catalog.pg_tablespace where spcname = '#{tablespace_name}');
        EOS
      )}
  end

end

