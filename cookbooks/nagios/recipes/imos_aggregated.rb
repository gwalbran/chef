#
# Cookbook Name:: nagios
# Recipe:: imos_aggregated
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

nagios_username = Chef::EncryptedDataBagItem.load("passwords", "nagios")['username']
nagios_password = Chef::EncryptedDataBagItem.load("passwords", "nagios")['password']

aggregated_monitors = Array.new

# Collect all monitors from data bags
data_bag('nagios_aggregated').each do |agg_monitor_id|
  agg_data_bag = Chef::DataBagItem.load('nagios_aggregated', agg_monitor_id)

  # Quote all monitors and join into one string, such that:
  # ["*-its-hob.emii.org.au", "*-nsp-mel.emii.org.au"]
  # Becomes:
  # '.*-its-hob.emii.org.au' '.*-nsp-mel.emii.org.au'
  monitors = "'" + agg_data_bag['monitors'].join("' '") + "'"

  aggregated_monitors << {
    :url          => agg_data_bag['url'],
    :service_name => agg_data_bag['service_name'],
    :monitors     => monitors
  }
end

# Generate parameters for nagios aggregated monitors
nagios_conf "aggregated" do
  variables(
    :nagios_username     => nagios_username,
    :nagios_password     => nagios_password,
    :aggregated_monitors => aggregated_monitors
  )
end

# Finally, we'll need ruby for check_nagios_monitors plugin, so...
package     'ruby'
package     'ruby-nokogiri'
gem_package 'trollop'
