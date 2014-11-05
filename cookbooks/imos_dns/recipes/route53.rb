#
# Cookbook Name:: imos_dns
# Recipe:: default
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

# A note about dns data bags:
# Since we can't have an ID of for a data bag with dots, we replace them
# with underscores, hence the calls to gsub("_", ".") and gsub(".", "_")
# It's a bit confusing, but not that.

# All records we'll update, in the format of:
# [ TYPE, NAME, VALUE ]
route53_records = {}

# Load all domains
all_domains = []
search(node['imos_dns']['dns_data_bag'], "*:*").each do |domain_data_bag|
  domain_normalized = domain_data_bag['id'].gsub("_", ".")
  all_domains.push(domain_normalized)
  route53_records[domain_normalized] = []
end

# AWS passwords
aws_access_key_id     = Chef::EncryptedDataBagItem.load("passwords", "aws")['access_key_id']
aws_secret_access_key = Chef::EncryptedDataBagItem.load("passwords", "aws")['secret_access_key']

# DNS updates for aliases section in node definition
nodes = search(:node, "fqdn:*")

nodes.each do |n|
  if n[node['imos_dns']['fqdn_attribute']]
    # Evaluate the nested IP address path, taken as an attribute
    ipaddress = eval("n" + node['imos_dns']['ipaddress_attribute'])
    # Set an A record for this host if we guessed it's public IP address
    # which should come from ohai plugin public_ipv4.rb
    if ipaddress
      hostname, domain = ImosDns.new.split_fqdn(all_domains, n[node['imos_dns']['fqdn_attribute']])
      if hostname && domain && n['fqdn'] && route53_records[domain]
        route53_records[domain].push(["A", n[node['imos_dns']['fqdn_attribute']], ipaddress])
      end
    end

    # Iterate over CNAME records and add them
    if n[node['imos_dns']['aliases_attribute']]
      n[node['imos_dns']['aliases_attribute']].each do |cname|
        hostname, domain = ImosDns.new.split_fqdn(all_domains, cname)
        if hostname && domain && route53_records[domain]
          route53_records[domain].push(["CNAME", cname, n[node['imos_dns']['fqdn_attribute']]])
        end
      end
    end
  end
end

# Depend on route53 cookbook
include_recipe "route53"

# Collect records for "unmanaged" nodes
all_domains.each do |domain|
  records = Chef::DataBagItem.load(node['imos_dns']['dns_data_bag'], domain.gsub(".", "_"))[node['imos_dns']['records_attribute']]
  if records && route53_records[domain]
    # Pretty simple - it's already in the right format
    route53_records[domain].concat(records)
  end
end

# Collect records from user data bags
users_domain = node['imos_dns']['users_domain']

search(:users, "ipaddress:*").each do |user_data_bag|
  username       = user_data_bag['id']
  user_ipaddress = user_data_bag['ipaddress']
  Chef::Log.info("User #{username}: #{users_domain} A #{username}.#{users_domain} #{user_ipaddress}")
  route53_records[users_domain].push(["A", "#{username}.#{users_domain}", user_ipaddress])
end

Chef::Log.info(route53_records)

########################
# Don't run on vagrant #
########################
if node['vagrant']
  Chef::Log.info("imos_dns is strictly disabled on mocked vagrant machines")
  return
end

# Lets do the actual updating
route53_records.each do |domain, records|
  records.each do |record|
    Chef::Log.info("Handling record: #{domain} #{record[0]} #{record[1]} #{record[2]}")
    route53_record "#{domain} #{record[0]} #{record[1]} #{record[2]}" do
      action :create
      type   record[0]
      name   record[1]
      value  record[2]

      # Get the ID of the data bag, which has underscores instead of dots
      zone_id               Chef::DataBagItem.load(node['imos_dns']['dns_data_bag'], domain.gsub(".", "_"))['zone_id']
      aws_access_key_id     aws_access_key_id
      aws_secret_access_key aws_secret_access_key
    end
  end
end
