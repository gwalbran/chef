#
# Cookbook Name:: rsync_chroot
# Provider:: user
#
# Copyright 2014, Dan Fruehauf
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

action :add do
  write_conf
end

action :remove do
  write_conf
end

protected
  #
  # Walk collection for :add rsync_chroot_user resources
  # Build and write authorized_keys
  #
  def write_conf
    begin
      Etc::getpwnam(new_resource.user)
    rescue
      Chef::Application.fatal!("User '#{new_resource.user}' does not exist, cannot create rsync_chroot entry")
    end

    authorized_keys_path =
      ::File.join(Dir.home(new_resource.user), ".ssh", "authorized_keys")

    if ! Dir.exist?(::File.dirname(authorized_keys_path))
      Dir.mkdir(::File.dirname(authorized_keys_path))
    end

    FileUtils.chown(new_resource.user, nil, ::File.dirname(authorized_keys_path))
    content = authorized_keys_content

    f = file(authorized_keys_path) do
      owner    new_resource.user
      mode     00644
      content  content.join("\n") + "\n"
    end

    new_resource.updated_by_last_action(f.updated?)
  end

  # The list of rsync_chroot user resources in the resource collection
  #
  # @return [Array<Chef::Resource>]
  def rsync_chroot_resources
    run_context.resource_collection.select do |resource|
      resource.is_a?(Chef::Resource::RsyncChrootUser)
    end
  end

  # An assembled line for authorized keys
  #
  # @return [String]
  def authorized_keys_line(rsync_options, directory, ssh_options, key, comment)
    if rsync_options.nil?
      rsync_options = node['rsync_chroot']['rsync_options']
    end

    if ssh_options.nil?
      ssh_options = node['rsync_chroot']['ssh_options']
    end

    line = "command=\"rsync #{rsync_options} --server . #{directory}\""
    line += "," + ssh_options
    line += " " + key
    line += " " + comment
  end

  # Builds authorized_keys content based on the list of rsync_chroot users
  # defined in the resource collection
  #
  # @return [Array<String>]
  def authorized_keys_content
    content = []
    rsync_chroot_resources.reduce({}) do |hash, resource|
      if resource.user == new_resource.user && resource.action == :add
        content << authorized_keys_line(
          resource.send('rsync_options'),
          resource.send('directory'),
          resource.send('ssh_options'),
          resource.send('key'),
          resource.send('comment')
        )
      end
    end

    content
  end
