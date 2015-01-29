#
# Cookbook Name:: imos_firewall
# Recipe:: default
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'iptables-ng::install'

### BEGIN MANDATORY RULES ###
# Hardcoded SSH rule, so we don't get blocked out EVERRRRR!
iptables_ng_rule 'utas_ssh' do
  ip_version 4
  rule       "-p tcp -s 131.217.38.0/24 --dport 22 -j ACCEPT"
end

# This is a must rule as well, to allow outgoing connections
iptables_ng_rule 'established_conns' do
  ip_version 4
  rule       "-m state --state RELATED,ESTABLISHED -j ACCEPT"
end

# Allow all traffic on localhost
iptables_ng_rule 'localhost' do
  rule "-i lo -j ACCEPT"
end

# DROP policy for INPUT chain
iptables_ng_chain 'INPUT' do
  policy 'DROP [0:0]'
end

# ACCEPT policy for OUTPUT chain
iptables_ng_chain 'OUTPUT' do
  policy 'ACCEPT [0:0]'
end
### END MANDATORY RULES ###

# Hardcoded rules for vagrant
if node['vagrant']
  iptables_ng_rule 'vagrant_internal' do
    ip_version 4
    rule       "-s 10.0.2.0/24 -j ACCEPT"
  end

  iptables_ng_rule 'vagrant_external' do
    ip_version 4
    rule       "-s 172.28.128.0/24 -j ACCEPT"
  end
end

# Firewall rules from data bags
if node['firewall']
  firewall_rules = []

  node['firewall']['entries'].each do |firewall_entry|
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

  # Clear old rules if there are any...
  for i in firewall_rules.size..99 do
    rule_to_delete = "/etc/iptables.d/filter/INPUT/chef_iptables_#{i}.rule_v4"
    if(File.exists?(rule_to_delete))
      Chef::Log.info("Deleting rule #{rule_to_delete}")
      execute "rm -f #{rule_to_delete}" do
        notifies :create, 'ruby_block[restart_iptables]', :delayed
      end
    end
  end

  Chef::Log.info("--- BEGIN IPTABLES FIREWALL ---")

  rule_number = 0
  firewall_rules.each do |firewall_rule|
    from_addr  = firewall_rule['from_addr']
    proto      = firewall_rule['proto'] || 'tcp'
    start_port = firewall_rule['start_port']
    end_port   = firewall_rule['end_port'] || start_port

    # Build a comma separated list of ports
    ports = start_port.to_s
    if end_port > start_port
      ports += ":#{end_port}"
    end

    # UDP protocols do not support states
    state = ""
    if "tcp" == proto
      state = "-m state --state NEW"
    end

    iptables_ng_rule "chef_iptables_#{rule_number}" do
      ip_version 4
      rule       "-p #{proto} #{state} -s #{from_addr} --dport #{ports} -j ACCEPT"
    end
    rule_number += 1

    Chef::Log.info("iptables rule: #{from_addr}:#{proto}:#{start_port}:#{end_port}")
  end

  Chef::Log.info("--- END IPTABLES FIREWALL ---")
end
