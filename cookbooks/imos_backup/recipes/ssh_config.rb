#
# Cookbook Name:: backup
# Recipe:: ssh_config
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#

def get_host_rsa_public(node)
  if node['keys'] && node['keys']['ssh'] && node['keys']['ssh']['host_rsa_public']
    return node['keys']['ssh']['host_rsa_public']
  else
    return nil
  end
end

def get_public_ip_address(node)
  if node['network'] && node['network']['public_ipv4']
    return node['network']['public_ipv4']
  else
    return nil
  end
end

# Create a model for each and every node
known_hosts_tuples   = []

# All the backup nodes
all_nodes = search(:node, "fqdn:*")

# Iterate on all nodes, configure their rsa public key
all_nodes.each do |n|
  host_name = n['fqdn'].downcase

  ssh_rsa_key = get_host_rsa_public(n)
  ipaddress = get_public_ip_address(n)

  if ssh_rsa_key && ipaddress
    Chef::Log.info("Getting SSH RSA public key from '#{host_name}'")
    known_hosts_tuples.push([ ipaddress, host_name, ssh_rsa_key ])
  end
end

# Create SSH configuration to pull backups with
backup_user_homedir = Chef::EncryptedDataBagItem.load("users", node[:backup][:username])['home']

directory "#{backup_user_homedir}/.ssh" do
  mode      0755
  owner     node[:backup][:username]
  group     node[:backup][:group]
  recursive true
end

backups_ssh_key = Chef::EncryptedDataBagItem.load("users", node[:backup][:username])['ssh_priv_key']
file ::File.join(backup_user_homedir, ".ssh", "id_rsa") do
  content backups_ssh_key
  owner   "#{node[:backup][:username]}"
  group   "#{node[:backup][:group]}"
  mode    0400
end

# Add all host keys to known hosts
template "#{backup_user_homedir}/.ssh/known_hosts" do
  source "known_hosts.erb"
  owner  "#{node[:backup][:username]}"
  group  "#{node[:backup][:group]}"
  mode   0644
  variables(:items => known_hosts_tuples.sort!)
end
