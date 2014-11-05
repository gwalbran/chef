#
# Cookbook Name:: imos_apache2
# Recipe:: vhosts
#
# Copyright 2012, IMOS
#
# All rights reserved - Do Not Redistribute
#

include_recipe "imos_apache2"
include_recipe "apache2::mod_ssl"
include_recipe "apache2::mod_proxy"
include_recipe "apache2::mod_proxy_http"
include_recipe "awstats"
include_recipe "logrotate"

# Get awstats username and password from data bag
awstats_data_bag = Chef::EncryptedDataBagItem.load("passwords", "awstats")

# Setup log rotation (/etc/logrotate.d/apache2) for apache
logrotate_app "apache2" do
  cookbook "logrotate"
  path "#{node['apache']['log_dir']}*.log"
  frequency "daily"
  postrotate "  /etc/init.d/apache2 reload > /dev/null"
  prerotate "  if [ -d /etc/logrotate.d/httpd-prerotate ]; then
    run-parts /etc/logrotate.d/httpd-prerotate;
  fi; "
  create "644 root adm"
end

if node['apache'] && node['apache']['vhosts']

  node['apache']['vhosts'].each do |vhost|

    web_app vhost['name'] do
      template          "vhost.conf.erb"
      cookbook          "imos_apache2"
      vhost             vhost['name']
      server_admin      vhost['server_admin']
      httpd_rules       vhost['httpd_rules']
      httpd_redirects   vhost['httpd_redirects']
      proxy_pass        vhost['proxy_pass']
      server_aliases    vhost['aliases']
      docroot           vhost['docroot']
      content_repo      vhost['content_repo']
      redirect_to_https vhost['https']
    end

    # Strip domain name from vhost, so we know which certificate to use
    domain = vhost['name'].split(".")[1..-1].join(".")

    web_app "#{vhost['name']}_ssl" do
      template        "vhost.conf.erb"
      cookbook        "imos_apache2"
      vhost           vhost['name']
      server_admin    vhost['server_admin']
      httpd_rules     vhost['httpd_rules']
      httpd_redirects vhost['httpd_redirects']
      proxy_pass      vhost['proxy_pass']
      server_aliases  vhost['aliases']
      docroot         vhost['docroot']
      content_repo    vhost['content_repo']
      domain          domain
      https           true
    end

    # Setup awstats
    awstats_domain_statistics "#{vhost['name']}" do
      log_location   "#{node['apache']['log_dir']}/#{vhost['name']}-access.log"
      skipped_hosts  node['imos_apache2']['awstats_skipped_hosts']
      data_directory node['imos_apache2']['awstats_dir']
      cron_contact   node['imos_apache2']['awstats_cron_contact']
    end

    htpasswd '/etc/apache2/htpasswd_awstats' do
      user     awstats_data_bag['username']
      password awstats_data_bag['password']
    end

    if vhost['content_repo']
      git vhost['docroot'] do
        repository vhost['content_repo']
        depth      1
      end
    end

  end
end
