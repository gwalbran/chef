#
# Cookbook Name:: imos_postgresql
# Library:: postgresql_helper
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

require 'json'
require 'fileutils'

module PostgresqlHelper

  @@configure_user = nil

  def self.set_configure_user(user)
    @@configure_user = user
  end

  def self.query_basic(port, database, query)
    cmd = Mixlib::ShellOut.new(
      (<<-EOS
        psql -t -p #{port} -d #{database} -w -c "#{query}"
      EOS
      ), :user => @@configure_user
    )
    cmd.run_command
    unless cmd.exitstatus == 0
      Chef::Application.fatal!("ShellOut failed '#{cmd.stderr}'")
    end
    cmd.stdout
  end

  def self.query_boolean(port, database, cmd)
    r = query_basic( port, database, cmd)
    case r.strip()
      when 't' then true
      when 'f' then false
      else
        Chef::Application.fatal!("Postgresql return value not recognized")
    end
  end

  ################################################
  # Serialize/Deserialize databases/roles states #
  ################################################

  def self.modified_roles(cluster, roles_to_create)
    existing_roles = load_roles_state(cluster)
    return diff_arrays(existing_roles, roles_to_create)
  end

  def self.deleted_roles(cluster, roles_to_create)
    existing_roles = load_roles_state(cluster)
    return diff_arrays(roles_to_create, existing_roles)
  end

  def self.modified_databases(cluster, databases_to_create)
    existing_databases = load_databases_state(cluster)
    return diff_arrays(existing_databases, databases_to_create)
  end

  def self.deleted_databases(cluster, databases_to_create)
    existing_databases = load_databases_state(cluster)
    return diff_arrays(databases_to_create, existing_databases)
  end

  def self.save_roles_state(cluster, roles)
    state_file = get_state_file(cluster, "roles")
    json_serialize(state_file, roles)
  end

  def self.save_databases_state(cluster, databases)
    state_file = get_state_file(cluster, "databases")
    json_serialize(state_file, databases)
  end

  private

  def self.load_roles_state(cluster)
    state_file = get_state_file(cluster, "roles")
    return json_deserialize(state_file)
  end

  def self.load_databases_state(cluster)
    state_file = get_state_file(cluster, "databases")
    return json_deserialize(state_file)
  end

  def self.json_serialize(file, object)
    ::FileUtils.mkdir_p(::File.dirname(file))
    ::File.open(file, 'w') { |file| file.write(pretty_json(object)) }
  end

  def self.json_deserialize(file)
    begin
      return JSON.parse(File.read(file))
    rescue
      return []
    end
  end

  def self.get_state_file(cluster, type)
    return ::File.join(Chef::Config[:file_cache_path], "imos_postgresql", "state", "#{cluster}-#{type}.json")
  end

  def self.pretty_json(content)
    return JSON.pretty_generate(content, :indent => "    ") + "\n"
  end

  def self.diff_arrays(lhs, rhs)
    # Get only the items that have been modified (in rhs) compared to lhs
    return rhs - lhs
  end

end

