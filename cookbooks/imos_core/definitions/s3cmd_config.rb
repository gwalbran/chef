#
# Cookbook Name:: imos_core
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

  package 's3cmd' do
    action :remove
  end
  package 'python-pip'
  python_package "s3cmd"

  mock_credentials = false

  if Chef::Config['dev']
    # Mock s3cmd on mocked machines
    cookbook_file "/usr/bin/s3cmd-mocked" do
      cookbook "imos_core"
      source   "s3cmd"
      mode     00755
    end

    # Mocked directory for bucket storage
    directory "/s3" do
      mode 00777
    end

    # Allow explicit overriding of that attribute. Allow real attributes even
    # on mocked machines if that is required
    if ! params[:mock_credentials].nil? && params[:mock_credentials] == false
      mock_credentials = false
    else
      mock_credentials = true
    end
  end

  if mock_credentials
    access_key = "MOCKED_access_key"
    secret_key = "MOCKED_secret_key"
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
