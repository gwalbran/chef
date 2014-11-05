#
# Cookbook Name:: imos_users
# Definition:: bash_aliases
#
# Copyright 2014, IMOS
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

# Install .bash_aliases for given user
define :bash_aliases do

  user = params[:user]

  # User creation might happen after this section of code, so we can just
  # install .bash_aliases in /etc/skel
  if node['etc']['passwd'][user]
    home_dir = node['etc']['passwd'][user]['dir']
    template "#{home_dir}/.bash_aliases" do
      source "bash_aliases.erb"
      owner  user
      mode   "0644"
      group  params[:group] || user
    end
  end

end
