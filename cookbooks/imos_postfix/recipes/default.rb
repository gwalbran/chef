#
# Cookbook Name:: imos_postfix
# Recipe:: default
#
# Copyright 2016, IMOS
#
# All rights reserved - Do Not Redistribute
#

node.override['postfix']['main']['smtp_sasl_auth_enable']= 'yes'
node.override['postfix']['main']['smtp_sasl_security_options']= 'noanonymous'
node.override['postfix']['main']['smtp_sasl_password_maps']= 'hash:/etc/postfix/sasl_passwd'
node.override['postfix']['main']['smtp_tls_CAfile']= "/opt/chef/embedded/ssl/certs/cacert.pem"
node.override['postfix']['main']['smtp_use_tls'] = 'yes'
node.override['postfix']['sasl_password_file'] = "#{node['postfix']['conf_dir']}/sasl_passwd"

sendgrid_vars = Chef::DataBagItem.load('passwords','sendgrid')
node.override['postfix']['main']['relayhost']= "[" + sendgrid_vars['host'] + "]:" + sendgrid_vars['port'].to_s
node.override['postfix']['sasl']['smtp_sasl_passwd']= sendgrid_vars['password']
node.override['postfix']['sasl']['smtp_sasl_user_name']= sendgrid_vars['username']

include_recipe "postfix::sasl_auth"
