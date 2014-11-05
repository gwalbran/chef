#
# Cookbook Name:: backup
# Recipe:: default
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#

# IMOS recipe, take care of user creation etc.
# The IMOS recipe will include the original backup rock recipe
include_recipe "imos_backup::default"
include_recipe "imos_backup::ssh_config"

# Create a model for each and every node
backup_start_time    = node[:imos_backup][:backup_start_time]
time_iter            = Time.local(1970, 1, 1, backup_start_time, 0)

# All the backup nodes
backup_nodes = search(:node, "fqdn:*").select {|n| n['run_list'].include?('role[backup]')}

# Iterate on all nodes, configure a pulling rsync backup for them
backup_nodes.each do |n|
  host_name = n['fqdn'].downcase

  Chef::Log.info("Configuring backup for '#{host_name}'")

  # make sure that:
  # 1. we're not trying to backup ourselves
  # 2. the host has a rsa public identity (for ssh/rsync)
  if (host_name != node['fqdn'].downcase) &&
    (n['keys'] && n['keys']['ssh'] && n['keys']['ssh']['host_rsa_public'])

    ssh_user                  = node[:backup][:username]
    # Remove backup directory from noe
    remote_backup_directory   = n['backup']['backup_dir']
    ssh_port                  = 22

    # Get the ipaddress of the node, always use the public IP address for the
    # sake of simplicity
    ipaddress = n['network']['public_ipv4']

    rsync_parameters = {
      "host_name"               => host_name,
      "remote_backup_directory" => remote_backup_directory,
      "ssh_user"                => ssh_user,
      "ssh_port"                => ssh_port,
      "ipaddress"               => ipaddress
    }

    backup host_name do
      template "rsync_pull"
      cookbook "imos_backup"
      params   ({:rsync_parameters => rsync_parameters})
    end
  end
end

# Manage users (only one user) in the restore group, so remote nodes can pull
# backups if needed with a restricted user
users_manage node[:imos_backup][:restore][:username]

# Create a link in the restore user homedir so it's easy for us to find the
# backups
restore_home_dir = Chef::EncryptedDataBagItem.load("users", node[:imos_backup][:restore][:username])['home']
link ::File.join(restore_home_dir, "backups") do
  to node[:backup][:backup_dir]
end
