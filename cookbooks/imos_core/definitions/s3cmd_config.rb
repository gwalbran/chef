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

  if Chef::Config['dev']
    # Mock s3cmd on mocked machines
    link "/usr/bin/s3cmd" do
      to "/bin/true"
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
      :https      => params[:https]
    )
  end
end
