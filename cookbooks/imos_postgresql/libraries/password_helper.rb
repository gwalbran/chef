#
# Cookbook Name:: imos_postgresql
# Recipe:: schema_support
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


module PasswordHelper

  def self.compute_password(name, password)
      # Compute md5 if necessary
      unless password.length == 35 and password =~ /^md5.*/
        password = "md5" + Digest::MD5.hexdigest("#{password}#{name}")
      end
      password
  end

end

