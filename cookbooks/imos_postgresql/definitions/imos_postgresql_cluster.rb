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


define :imos_postgresql_cluster, :name => nil, :version => nil, :config => nil, :hba => nil, :recovery => nil, :basebackup => nil do

  # Ease syntax
  name = params[:name]
  version = params[:version]
  config = params[:config]
  hba = params[:hba]
  recovery = params[:recovery]
  basebackup = params[:basebackup]

  base_config_dir = "/etc/postgresql/#{version}/#{name}"
  base_data_dir = "/var/lib/postgresql/#{version}/#{name}"

  hba_conf_file = "#{base_config_dir}/pg_hba.conf"
  postgresql_conf_file = "#{base_config_dir}/postgresql.conf"

  # Add synthesized values to config
  config['hba_file'] = hba_conf_file
  config['data_directory'] = base_data_dir if config['data_directory'].nil?

  data_directory = config['data_directory']

  # recovery.conf must be in base_data, and cannot be configured otherwise
  recovery_conf_file = "#{data_directory}/recovery.conf"


  # Drop default postgres cluster, that will take resources like tcp/ip ports
  execute "drop-default-postgres-cluster" do
    command <<-EOS
      pg_ctlcluster #{version} main stop || exit 1;
      PGDATADIR=$( pg_lsclusters -h | tr -s ' ' | grep ' main ' | cut -d " " -f 6 ) || exit 1;
      if [ -d "$PGDATADIR" ]; then
        mv $PGDATADIR $PGDATADIR.$(date '+%F.%s') || exit 1;
      fi
      pg_dropcluster #{version} main || exit 1;
    EOS
    only_if {
      # postgresql.conf exists and wasn't generated by chef
      default_postgresql_conf = "/etc/postgresql/#{version}/main/postgresql.conf"
      File.exist?(default_postgresql_conf) and
        ! File.open(default_postgresql_conf) { |file| file.grep(/dropped off by chef/) }.any?
    }
    user "root"
  end

  # Create data directory if needed
  directory data_directory do
    owner     node[:imos_postgresql][:postgresql_service_user]
    group     node[:imos_postgresql][:postgresql_service_group]
    mode      0700
    recursive false
    action    :create
  end



  unless basebackup

    # Create cluster - simple case
    execute "#{name}-create" do
      # TODO Fix the dummy snakeoil certs
      # See, http://blog.roomthirteen.de/2013/01/07/solved-installing-postgresql-on-ubuntu-12-04/
      command <<-EOS
          pg_createcluster -d #{data_directory} #{version} #{name}
          ln -f -s /etc/ssl/certs/ssl-cert-snakeoil.pem #{data_directory}/server.crt || exit;
          ln -f -s /etc/ssl/private/ssl-cert-snakeoil.key #{data_directory}/server.key || exit;
        EOS
      only_if  {
        cmd = Mixlib::ShellOut.new(
          (<<-EOS
            pg_lsclusters | grep -q -E '^#{version} +#{name} +';
          EOS
          ), :user => 'root'
        )
        cmd.run_command
        cmd.exitstatus != 0
      }
    end
  else

    # Create cluster - standby mode
    execute "#{name}-create" do
      # TODO Fix the dummy snakeoil certs
      command <<-EOS
          pg_createcluster -d #{data_directory} #{version} #{name} || exit
          rm -rf #{data_directory}/* || exit
          export PGPASSWORD=#{basebackup['password']};
          pg_basebackup -h #{basebackup['host']} -p #{basebackup['port']} -U #{basebackup['user']} -w -x --pgdata=#{data_directory} || exit;
          chown -R #{node[:imos_postgresql][:postgresql_service_group]}:#{node[:imos_postgresql][:postgresql_service_user]} #{data_directory} || exit;
          ln -f -s /etc/ssl/certs/ssl-cert-snakeoil.pem #{data_directory}/server.crt || exit;
          ln -f -s /etc/ssl/private/ssl-cert-snakeoil.key #{data_directory}/server.key || exit;
        EOS
      only_if  {
        cmd = Mixlib::ShellOut.new(
          (<<-EOS
            pg_lsclusters | grep -q -E '^#{version} +#{name} +';
          EOS
          ), :user => 'root'
        )
        cmd.run_command
        cmd.exitstatus != 0
      }
      timeout 2 * 3600
    end
  end


  # Cluster restart resource
  execute "#{name}-restart" do
    command <<-EOS
        pg_ctlcluster #{version} #{name} stop --force;
        pg_ctlcluster #{version} #{name} start;
      EOS
    action :nothing
  end

  if recovery
    # Order shouldn't matter here since we specify data dir on cluster creation
    template recovery_conf_file do
      source    "postgresql.conf.erb"
      owner     node[:imos_postgresql][:postgresql_service_user]
      group     node[:imos_postgresql][:postgresql_service_group]
      mode      0600
      notifies  :run, "execute[#{name}-restart]", :immediately
      variables({
        :config => recovery
      })
    end
  else
    # Should explicitly delete it here,
  end

  # Order shouldn't matter here since we specify data dir on cluster creation
  template postgresql_conf_file do
    source    "postgresql.conf.erb"
    owner     node[:imos_postgresql][:postgresql_service_user]
    group     node[:imos_postgresql][:postgresql_service_group]
    mode      0600
    notifies  :run, "execute[#{name}-restart]", :immediately
    variables({
      :config => config
    })
  end

  # Create pg_hba.conf
  template hba_conf_file do
    source    "pg_hba.conf.erb"
    owner     node[:imos_postgresql][:postgresql_service_user]
    group     node[:imos_postgresql][:postgresql_service_group]
    mode      00600
    notifies  :run, "execute[#{name}-restart]", :immediately
    variables({
      :config => hba
    })
  end

end

