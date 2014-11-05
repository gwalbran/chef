#
# Cookbook Name:: imos_devel
# provider:: vagrant_plugin
#
# Copyright (C) 2014 IMOS
#
# All rights reserved - Do Not Redistribute
#

# Install a vagrant plugin
action :install do

  home    = new_resource.home
  version = new_resource.version
  user    = new_resource.user
  name    = new_resource.name

  code    = "HOME=#{home} vagrant plugin install #{name}"
  if new_resource.version
    code += " --plugin-version #{version}"
  end

  # Shell command to determine if a plugin is installed
  plugin_is_installed = 'HOME=%s vagrant plugin list | grep -q "\b%s\b"' % [home, name]

  bash "vagrant_plugin_#{name}_#{version}" do
    code   code
    user   user
    cwd    home
    not_if plugin_is_installed, :user => user
  end

end
