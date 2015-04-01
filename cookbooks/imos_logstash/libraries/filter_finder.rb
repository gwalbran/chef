#
# Cookbook Name:: imos_logstash
# Recipe:: filter_finder
#
# Copyright 2015, IMOS
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

module FilterFinder
  @@available_filter_configs = %w{
      aatams
      geonetwork
      geoserver
      portal
  }

  def self.get_filter_config(application_name)
    filter_config = nil
    begin
      app_data_bag = Chef::DataBagItem.load("imos_artifacts", application_name)
      filter_config = app_data_bag['logstash_filter_config']
    rescue
      application_name_short = application_name.split('_')[0].downcase
      if @@available_filter_configs.include?(application_name_short)
        filter_config = application_name_short
      end
    end

    return filter_config
  end

end

