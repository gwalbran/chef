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

end

