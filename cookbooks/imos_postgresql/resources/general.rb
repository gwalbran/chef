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


actions :create

default_action :create

attribute :name, :name_attribute => true, :required => true, :kind_of => String

attribute :msg, :required => false, :kind_of => String

attribute :port, :required => true, :kind_of => Integer

attribute :database, :required => true, :kind_of => String

attribute :sql, :required => true, :kind_of => String

