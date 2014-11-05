#
# Cookbook Name:: talend
# Recipe:: bash_aliases
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#
# No default recipe for this cookbook.  This cookbook provides resources for
# other cookbooks to use


template "/etc/profile.d/_imos_talend.sh" do
  source 'talend.sh.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  variables(
    :talend_jobs_dir => node['talend']['jobs_dir']
  )
end
