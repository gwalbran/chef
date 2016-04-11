#
# Cookbook Name:: imos_postfix
# Recipe:: default
#
# Copyright 2016, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "postfix::sasl_auth"

node.override['postfix']['smtp_sasl_auth_enable']= 'yes'
node.override['postfix']['smtp_sasl_security_options']= 'noanonymous'
node.override['postfix']['smtp_sasl_password_maps']= 'hash:/etc/postfix/sasl_passwd'
node.override['postfix']['smtp_tls_cafile']= "/opt/chef/embedded/ssl/certs/cacert.pem"
node.override['postfix']['smtp_tls_security_level']= 'encrypt'

sendgrid_vars = Chef::DataBagItem.load('passwords','sendgrid')
node.override['postfix']['relayhost']= "[" + sendgrid_vars['host'] + "]:" + sendgrid_vars['port'].to_s
node.override['postfix']['smtp_sasl_passwd']= sendgrid_vars['password']
node.override['postfix']['smtp_sasl_user_name']= sendgrid_vars['username']


