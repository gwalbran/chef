#
# Cookbook:: apache2
# Recipe:: mod_privileges
#
# Copyright:: 2016, Alexander van Zoest
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

# https://httpd.apache.org/docs/trunk/mod/mod_privileges.html
# Available in Apache 2.3 and up, on Solaris 10 and OpenSolaris platforms
if node['apache']['version'] == '2.4' && node['platform_family'] == 'solaris'
  apache_module 'privileges'
else
  log 'Ignoring apache2::mod_privileges. Not available until apache 2.3 and only on Solaris'
end
