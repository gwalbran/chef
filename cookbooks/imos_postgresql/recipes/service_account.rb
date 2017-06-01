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

# SSH public key
ssh_dir = "#{node['imos_postgresql']['postgresql_service_user_home']}/.ssh"
directory ssh_dir do
  owner node['imos_postgresql']['postgresql_service_user']
  group node['imos_postgresql']['postgresql_service_group']
end

postgres_pub_key = Chef::EncryptedDataBagItem.load('passwords', node['imos_postgresql']['postgresql_service_user'])['ssh_pub_key']
file "#{ssh_dir}/authorized_keys" do
  content postgres_pub_key
  owner node['imos_postgresql']['postgresql_service_user']
  group node['imos_postgresql']['postgresql_service_group']
  mode 00400
  only_if { postgres_pub_key }
end

# Support for replication connections
if node['postgresql']['known_hosts']

  # Deploy the private key
  postgres_priv_key = Chef::EncryptedDataBagItem.load('passwords', node['imos_postgresql']['postgresql_service_user'])['ssh_priv_key']
  file "#{ssh_dir}/id_rsa" do
    content postgres_priv_key
    owner node['imos_postgresql']['postgresql_service_user']
    group node['imos_postgresql']['postgresql_service_group']
    mode 00400
    only_if { postgres_priv_key }
  end


  # TODO - Couldn't get this working in vagrant, for localhost, since not enough of the networking configuration is mocked
  #
  # known_hosts_tuples   = []
  #
  # # All the backup nodes
  # all_nodes = search(:node, "fqdn:*")
  #
  # # Iterate on all nodes, configure a pulling rsync backup for them
  # all_nodes.each do |n|
  #   host_name = n['fqdn'].downcase
  # if n.contains node['postgresql']['known_hosts'] && ...
  #   if n['keys'] && n['keys']['ssh'] && n['keys']['ssh']['host_rsa_public']
  #     ipaddress = n['network']['public_ipv4']
  #     known_hosts_tuples.push([ ipaddress, host_name, n['keys']['ssh']['host_rsa_public'] ])
  #   end
  # end
  #
  # # Add all host keys to known hosts
  # template "#{node[:imos_postgresql][:postgresql_service_user]}/.ssh/known_hosts" do
  #   source "known_hosts.erb"
  #   cookbook "imos_backup"
  #   owner  "#{node[:backup][:username]}"
  #   group  "#{node[:backup][:group]}"
  #   mode   0644
  #   variables(:items => known_hosts_tuples.sort!)
  # end

  # HACK for the moment
  known_hosts="#{node['imos_postgresql']['postgresql_service_user_home']}/.ssh/known_hosts"

  node['postgresql']['known_hosts'].each do |host|
    execute "known-hosts-#{host}" do
      command <<-EOS
          ssh-keyscan -H #{host} >> #{known_hosts}
      EOS
      not_if { File.exist?(known_hosts) and File.open(known_hosts) { |file| file.grep(/#{host}/) }.any? }
    end
  end
end
