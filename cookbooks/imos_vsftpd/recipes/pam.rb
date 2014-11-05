#
# Cookbook Name:: imos_vsftpd
# Recipe:: pam
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#

package "libpam-pwdfile"

# PAM for vsftpd authentication
template "/etc/pam.d/pam_vsftpd" do
  source "pam_vsftpd.erb"
  owner  "root"
  group  "root"
  mode   00644
end
