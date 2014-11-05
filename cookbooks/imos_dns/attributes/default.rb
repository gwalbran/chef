# Default attributes for imos_dns cookbook

default['imos_dns']['dns_data_bag']        = "dns"
default['imos_dns']['aliases_attribute']   = "aliases"
default['imos_dns']['fqdn_attribute']      = "fqdn"
default['imos_dns']['ipaddress_attribute'] = "['network']['public_ipv4']"
default['imos_dns']['records_attribute']   = "records"

default['imos_dns']['users_domain']        = "emii.org.au"

default['imos_dns']['etc_hosts']           = {}
