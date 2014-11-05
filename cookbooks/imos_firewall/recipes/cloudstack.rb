#
# Cookbook Name:: imos_firewall
# Recipe:: cloudstack
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

# This recipe simply prints a script to run to get your firewall rules

firewall_command_prefix = "knife cs firewallrule create"
firewall_rules = []

if node['firewall'] && node['firewall']['cloudstack'] && node['firewall']['cloudstack']['hostname']
  cloudstack_hostname = node['firewall']['cloudstack']['hostname']
  node['firewall']['cloudstack']['entries'].each do |firewall_entry|

    if firewall_entry['data_bag']
      # Rules from defined data bag
      firewall_data_bag = Chef::DataBagItem.load("firewall", firewall_entry['data_bag'])
      firewall_data_bag['entries'].each do |firewall_entry_db|
        firewall_rules.concat(firewall_entry_db['rules'])
      end
    else
      firewall_rules.concat(firewall_entry['rules'])
    end
  end


  Chef::Log.info("--- BEGIN FIREWALL SCRIPT ---")
  firewall_script_location = "#{Chef::Config[:file_cache_path]}/firewall_cloudstack.sh"
  firewall_script = File.open(firewall_script_location, 'w')
  firewall_script.write("#!/bin/sh\n")

  firewall_rules.each do |firewall_rule|
    from_addr  = firewall_rule['from_addr']
    proto      = firewall_rule['proto'] || 'TCP'
    start_port = firewall_rule['start_port']
    end_port   = firewall_rule['end_port'] || start_port

    firewall_command = "#{firewall_command_prefix} #{cloudstack_hostname} #{start_port}:#{end_port}:#{proto}:#{from_addr}"
    Chef::Log.info(firewall_command)
    firewall_script.write("#{firewall_command}\n")
  end

  Chef::Log.info("--- END FIREWALL SCRIPT ---")
  Chef::Log.info("Firewall script can also be found at #{firewall_script_location}")
end



