#
# Cookbook Name:: imos_postgresql
# Recipe:: replication_standby
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

ssh_dir = "#{node['imos_postgresql']['postgresql_service_user_home']}/.ssh"
authorized_keys_file = ::File.join(ssh_dir, 'authorized_keys')

postgres_pub_key = Chef::EncryptedDataBagItem.load('passwords', node['imos_postgresql']['postgresql_service_user_databag'])['ssh_pub_key']

file authorized_keys_file do
  content postgres_pub_key
  owner node['imos_postgresql']['postgresql_service_user']
  group node['imos_postgresql']['postgresql_service_group']
  mode 00400
  only_if { postgres_pub_key }
end
