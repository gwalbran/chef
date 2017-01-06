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

def whyrun_supported?
  true
end

# Add
action :add do
  # Parameters
  backup_name     = new_resource.backup_name
  params          = new_resource.params
  cookbook        = new_resource.cookbook || "backup"
  template        = new_resource.template || "default"
  model_file_path = "#{node[:backup][:models_dir]}/#{backup_name}.sh"

  Chef::Log.info "Adding backup model '#{backup_name} at '#{model_file_path}'"

  # Create the template
  template model_file_path do
    source   "model_#{template}.sh.erb"
    cookbook cookbook
    owner    node[:backup][:username]
    group    node[:backup][:group]
    mode     0644
    variables(
      :backup_name => backup_name,
      :params      => params
    )
  end
  new_resource.updated_by_last_action(true)
end

# Remove
action :remove do
  # Parameters
  model_file_path = "#{node[:backup][:models_dir]}/#{backup_name}.sh"

  if ::File.exists?(model_file_path)
    Chef::Log.info "Removing '#{new_resource.command_name}' from '#{model_file_path}'"
    file model_file_path do
      action :delete
    end
    new_resource.updated_by_last_action(true)
  end
end

