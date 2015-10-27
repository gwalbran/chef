#
# Cookbook Name:: imos_code
# Definition:: s3cmd_config
#
# Copyright (C) 2015 IMOS
#
# All rights reserved - Do Not Redistribute
#
# Deploys s3cmd config file

define :s3cmd_config do
  access_key = params[:access_key]
  secret_key = params[:secret_key]
  host_base  = params[:host_base] || node['imos_core']['s3cmd']['host_base']

  if Chef::Config['dev']
    # Mock s3cmd on mocked machines
    cookbook_file "/usr/bin/s3cmd" do
      cookbook "imos_core"
      source   "s3cmd"
      mode     00755
    end

    # mocked directory for bucket storage
    directory "/s3" do
      mode 00777
    end

    access_key = "MOCKED_access_key"
    secret_key = "MOCKED_secret_key"
  else
    package 's3cmd'
  end

  template params[:name] do
    source   "s3cfg.erb"
    cookbook "imos_core"
    mode     0600
    owner    params[:owner]
    variables(
      :access_key => access_key,
      :secret_key => secret_key,
      :host_base  => host_base,
      :https      => params[:https]
    )
  end
end
