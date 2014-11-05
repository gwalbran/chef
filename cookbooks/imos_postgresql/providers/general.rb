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


action :create do
  unless new_resource.msg
    sql = new_resource.sql.strip.gsub(/\n+/, ' ').gsub(/\s\s+/,' ')
    Chef::Log.info("#{new_resource.database}(#{new_resource.port}) #{sql}")
  else
    Chef::Log.info(new_resource.msg)
  end
  PostgresqlHelper.query_basic(new_resource.port, new_resource.database, new_resource.sql)
end

