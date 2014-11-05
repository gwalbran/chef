#
# Cookbook Name:: imos_users
# Recipe:: default
#
# Copyright 2011, Eric G. Wolfe
# Copyright 2009-2011, Opscode, Inc.
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

# Install .bash_aliases in /etc/skel
template "/etc/skel/.bash_aliases" do
  source "bash_aliases.erb"
end

# Copy node attributes
group_data_bags = []
if node['imos_users'] && node['imos_users']['groups']
  group_data_bags.concat(node['imos_users']['groups'])
end

# Always include the admin group
group_data_bags << "admin"

group_data_bags.uniq.each do |group_data_bag|
  group_name = Chef::DataBagItem.load('groups', group_data_bag)['id']
  group_id   = Chef::DataBagItem.load('groups', group_data_bag)['gid']

  Chef::Log.info("Creating group '#{group_name}' with gid '#{group_id}'")

  users_manage group_name do
    group_id group_id.to_i
    action   [ :remove, :create ]
  end

  users = search('users', "groups:#{group_name} AND NOT action:remove")

  # Install .bash_aliases for existing users if they are already defined
  users.each do |u|
    bash_aliases do
      user u['id']
    end
  end
end

# Hardcoded (for safety) allow admin group sudo
sudo 'admin' do
  group    "admin"
  runas    "root"
  commands ["ALL"]
  host     "ALL"
  nopasswd true
end
