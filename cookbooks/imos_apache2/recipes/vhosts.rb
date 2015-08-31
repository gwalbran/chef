#
# Cookbook Name:: imos_apache2
# Recipe:: vhosts
#
# Copyright 2012, IMOS
#
# All rights reserved - Do Not Redistribute
#

if node['apache'] && node['apache']['vhosts']
  node['apache']['vhosts'].each do |vhost|
    apache_for_webapp vhost['name'] do
      vhost             vhost['name']
      aliases           vhost['aliases']
      rules             vhost['httpd_rules']
      redirects         vhost['httpd_redirects']
      proxy_pass        vhost['proxy_pass']
      docroot           vhost['docroot']
      directory_index   vhost['directory_index'] || node['imos_apache2']['directory_index']
      content_repo      vhost['content_repo']
      https             vhost['https']
      sts               vhost['sts']
    end

  end
end

# Setup log rotation (/etc/logrotate.d/apache2) for apache
logrotate_app "apache2" do
  cookbook "logrotate"
  path File.join(node['apache']['log_dir'], '*.log')
  frequency "daily"
  postrotate "  /etc/init.d/apache2 reload > /dev/null"
  prerotate "  if [ -d /etc/logrotate.d/httpd-prerotate ]; then
    run-parts /etc/logrotate.d/httpd-prerotate;
  fi; "
  create "644 root adm"
end
