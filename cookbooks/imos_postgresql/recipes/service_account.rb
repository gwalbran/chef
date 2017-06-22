#
# Cookbook Name:: imos_postgresql
# Recipe:: service_account
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

user node['imos_postgresql']['postgresql_service_user'] do
  comment 'Postgres'
  home '/var/lib/postgresql'
  system true
  shell '/bin/bash'
  not_if { node['etc']['passwd'].key?([node['imos_postgresql']['postgresql_service_user']]) }
end

group node['imos_postgresql']['postgresql_service_group'] do
  members node['imos_postgresql']['postgresql_service_user']
  system true
  not_if { node['etc']['passwd'].key?([node['imos_postgresql']['postgresql_service_group']]) }
end

group 'ssl-cert' do
  action :modify
  members node['imos_postgresql']['postgresql_service_user']
  append true
end
