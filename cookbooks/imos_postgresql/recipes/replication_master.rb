#
# Cookbook Name:: imos_postgresql
# Recipe:: replication_master
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
known_hosts = ::File.join(ssh_dir, 'known_hosts')

# Support for replication connections
if node['postgresql']['known_hosts']

  require 'resolv'

  # Deploy the private key
  postgres_priv_key = Chef::EncryptedDataBagItem.load('passwords', node['imos_postgresql']['postgresql_service_user_databag'])['ssh_priv_key']
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
  node['postgresql']['known_hosts'].each do |host|

    keyscan_hosts = host
    begin
      host_ip = Resolv.getaddress host
      keyscan_hosts = "#{host},#{host_ip}"
    rescue Resolv::ResolvError => e
      Chef::Log.warn "Unable to resolve IP address for host #{host}. Error: #{e.message}"
    end

    execute "known-hosts-#{host}" do
      command <<-EOS
          ssh-keyscan #{keyscan_hosts} >> #{known_hosts}
      EOS
      not_if { File.exist?(known_hosts) and File.open(known_hosts) { |file| file.grep(/#{host}/) }.any? }
    end
  end
end
