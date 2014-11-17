#
# Copyright 2012, IMOS
#
# All rights reserved - Do Not Redistribute
#

# Get awstats username and password from data bag
awstats_data_bag = Chef::EncryptedDataBagItem.load("passwords", "awstats")

define :apache_for_webapp do
  name           = params[:name]
  apps           = params[:apps]
  tomcat_port    = params[:tomcat_port]
  vhost          = params[:vhost]
  server_aliases = params[:aliases]
  cached         = params[:cached]
  https          = params[:https]
  rules          = params[:rules]

  include_recipe "apache2::mod_ssl"
  include_recipe "apache2::mod_proxy"
  include_recipe "apache2::mod_proxy_http"
  include_recipe "awstats"
  include_recipe "logrotate"

  # Some modules will require caching - enable the apache module then
  apache_module 'proxy_http'

  # Strip domain name from vhost, so we know which certificate to use
  domain = vhost.split(".")[1..-1].join(".")

  web_app vhost do
    vhost             vhost
    template          "webapp.conf.erb"
    cookbook          "imos_apache2"
    apps              apps
    app_port          tomcat_port
    server_aliases    server_aliases
    cached            cached
    redirect_to_https https
    domain            domain
    rules             rules
  end

  web_app "#{vhost}_ssl" do
    vhost          vhost
    template       "webapp.conf.erb"
    cookbook       "imos_apache2"
    apps           apps
    app_port       tomcat_port
    server_aliases server_aliases
    cached         cached
    https          true
    domain         domain
    rules          rules
  end

  # Setup awstats
  awstats_domain_statistics vhost do
    log_location   "#{node['apache']['log_dir']}/#{vhost}-access.log"
    skipped_hosts  node['imos_apache2']['awstats_skipped_hosts']
    data_directory node['imos_apache2']['awstats_dir']
    cron_contact   node['imos_apache2']['awstats_cron_contact']
  end

  htpasswd '/etc/apache2/htpasswd_awstats' do
    user     awstats_data_bag['username']
    password awstats_data_bag['password']
  end

end