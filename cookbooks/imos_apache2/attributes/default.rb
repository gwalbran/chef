# Do not record awstats for these hosts
default['imos_apache2']['awstats_skipped_hosts'] =
[
  "103.6.253.233",          # nagios.aodn.org.au
  "192.168.100.94",         # nagios.aodn.org.au Internal address
  "REGEX[^131\.217\.38\.]", # regex for IMOS subnet
  "131.217.2.24",           # emii1.its.utas.edu.au, why is it blocked?!
  "131.217.6.6"             # proxy1.utas.edu.au, why is it blocked?!
]

default['imos_apache2']['awstats_dir'] = "/var/lib/awstats"

default['imos_apache2']['awstats_cron_contact'] = node['email_contact'] || "root@localhost"

default['imos_apache2']['static_dir'] = ::File.join(node['apache']['docroot_dir'], "static")
default['imos_apache2']['directory_index'] = "index.htm index.html"

# Default options for STS (Strict Transport Security)
default['imos_apache2']['sts']['options'] = "max-age=15768000;includeSubDomains"

default['apache']['mpm'] = "prefork"
