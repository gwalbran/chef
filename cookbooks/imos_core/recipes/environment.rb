#
# Cookbook Name:: imos_core
# Recipe:: environment
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#

# Ideally, that's what I'd like to have here, however we don't utilize
# enrvironment quite yet
#environment = node['chef_environment']

# Treat then everything as production unless running in dev mode
if Chef::Config[:dev]
    environment = "development"
else
    environment = "production"
end

file "/etc/profile.d/_imos_environment.sh" do
  content "#!/bin/bash
export _IMOS_ENVIRONMENT=#{environment}
export EDITOR=vi
"
  mode 00644
  owner "root"
  group "root"
end
