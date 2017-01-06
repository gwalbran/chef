#
# Cookbook Name:: backup
# Recipe:: default
#
# Copyright (C) 2013 Dan Fruehauf <malkodan@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#

# Require some pretty basic packages
node[:backup][:packages].each do |package|
  package package
end

# Create backup user but only if it doesn't exist
if ! User(node[:backup][:username])
  group node[:backup][:group]

  user node[:backup][:username] do
    home node[:backup][:base_dir]
    gid  node[:backup][:group]
  end
end

# Honour the fact that sometimes the backup directory may be on a NFS volume or
# somewhere which we cannot chown it
directory node[:backup][:backup_dir] do
  mode      0775
  recursive true
  notifies  :run, "ruby_block[chown_backup_dir]", :immediately
end

# Try to change permissions on backup_dir, but don't fail if we cannot
ruby_block "chown_backup_dir" do
  block do
    Chef::Log.warn("Chowning '#{node[:backup][:backup_dir]}'")
    begin
      shell_out("chown #{node[:backup][:username]}:#{node[:backup][:group]} #{node[:backup][:backup_dir]}")
    rescue
      Chef::Log.warn("Could not chown directory '#{node[:backup][:backup_dir]}', but we'll proceed anyway")
    end
  end
  action :nothing
end

# Create all directories with right permissions
[
  node[:backup][:base_dir],
  node[:backup][:models_dir],
  node[:backup][:bin_dir],
  node[:backup][:log_dir]
].each do |directory|
  directory directory do
    mode      0775
    owner     node[:backup][:username]
    group     node[:backup][:group]
    recursive true
  end
end

# Sync git repository
git node[:backup][:bin_dir] do
  repository node[:backup][:git_url]    || "https://github.com/danfruehauf/backup.git"
  revision   node[:backup][:git_branch] || "master"
  action     :sync
  user       node[:backup][:username]
  group      node[:backup][:group]
end
