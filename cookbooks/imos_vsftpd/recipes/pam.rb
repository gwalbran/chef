#
# Cookbook Name:: imos_vsftpd
# Recipe:: pam
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#

package "libpam-pwdfile"

pam_pwdfile_lib = node['lsb']['codename'].include?("precise") ? '/lib/security/pam_pwdfile.so' : '/lib/x86_64-linux-gnu/security/pam_pwdfile.so'

# PAM for vsftpd authentication
template "/etc/pam.d/pam_vsftpd" do
  source "pam_vsftpd.erb"
  owner  "root"
  group  "root"
  mode   00644
  variables(
    :pam_pwdfile_lib => pam_pwdfile_lib
  )
end
