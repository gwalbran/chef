define :tomcat_instance do
  name            = @params[:name]
  instance        = @params[:instance]
  port            = instance['port']
  java_opts       = instance['java_options'] || node['tomcat']['java_options']
  parallel_deploy = instance['parallel_deploy']
  admin_port      = @params[:admin_port] || "1#{port}"

  user                = node['tomcat']['user']
  group               = node['tomcat']['group']
  tomcat_version      = node['tomcat']['version']
  tomcat_fine_version = node['tomcat']['fine_version']
  instance_dir        = "#{node['tomcat']['base']}/#{name}"
  server_xml          = ::File.join(instance_dir, 'conf', 'server.xml')
  init_d_service      = "tomcat_#{name}"
  init_d_service_path = ::File.join('etc', 'init.d', init_d_service)
  logging_properties  = ::File.join(instance_dir, 'conf', 'logging.properties')
  version_sh          = ::File.join(instance_dir, "bin", "version.sh")

  setenv_file_path = ::File.join(instance_dir, "bin", "setenv.sh")

  server_info_properties_dir = ::File.join(instance_dir, "lib", "org", "apache", "catalina", "util")
  server_info_properties     = ::File.join(server_info_properties_dir, "ServerInfo.properties")

  jmx_remote_port = "#{node['tomcat']['jmx_remote_port_prefix']}#{port}"
  java_opts += " #{node['tomcat']['jmx_options'] % jmx_remote_port}"

  # Create directory for each instance.
  directory instance_dir do
    owner     user
    group     group
    recursive true
    mode      00755
  end

  installed_tomcat_version = ""
  if ::File.exist?(version_sh)
    installed_tomcat_version = `#{version_sh} 2> /dev/null | grep '^Server number:'`
    installed_tomcat_version.gsub!(/Server number:\s*/, '') # 'Server number:  7.0.61.0' -> '7.0.61.0'
    installed_tomcat_version.gsub!(/\.\d?$/, '') # '7.0.61.0' -> '7.0.61'
    installed_tomcat_version.chomp!
    Chef::Log.info "Detected tomcat version '#{installed_tomcat_version}' at '#{instance_dir}'"
  end

  # Install tomcat if new tomcat downloaded, or tomcat directory is empty
  if installed_tomcat_version != tomcat_fine_version
    Chef::Log.info "Installing tomcat instance '#{name}' to '#{instance_dir}', version '#{tomcat_fine_version}'"

    tomcat_tar_gz = ::File.join(Chef::Config[:file_cache_path], "tomcat-#{tomcat_fine_version}.tar.gz")
    remote_file tomcat_tar_gz do
      source   node['tomcat']['pkg_url']
      mode     0644
      checksum node['tomcat']['pkg_checksum']
      action   :create_if_missing
    end

    bash "tomcat_extract_#{name}" do
      user "root"
      code <<-EOH
        tar --overwrite --strip-components=1 -C #{instance_dir} -xf #{tomcat_tar_gz} && \
        rm -rf #{instance_dir}/webapps/{examples,docs,host-manager,manager} && \
        chown -R #{user}:#{user} #{instance_dir}
      EOH
    end
  else
    Chef::Log.info "No need to install/update tomcat at '#{instance_dir}', already at version '#{installed_tomcat_version}'"
  end

  # Create init.d script for each instance.
  template init_d_service_path do
    cookbook "tomcat"
    source   "tomcat.erb"
    owner    "root"
    group    "root"
    mode     00755
    variables(
      :name      => name,
      :java_opts => java_opts
    )
  end

  template server_xml do
    cookbook "tomcat"
    source   "server_tomcat#{tomcat_version}.xml.erb"
    owner    user
    group    group
    mode     "0644"
    variables(
        :instance => instance,
        :ports => { :connector_port => port, :port => admin_port },
        :parallel_deploy => parallel_deploy
    )
  end

  template logging_properties do
    cookbook "tomcat"
    source   "logging_properties.xml.erb"
    owner    user
    group    group
    mode     "0644"
    variables(
      :level => node['tomcat']['log_level']
    )
  end

  directory server_info_properties_dir do
    owner      user
    group      group
    mode       0755
    recursive  true
    action     :create
  end

  # Conditionally set Tomcat environment variables via the setenv.sh mechanism
  setenv_variables = {}
  if instance['environment_variables']
    setenv_variables.merge!(instance['environment_variables'])
  end

  if instance['aws_credentials']
    data_bag = Chef::EncryptedDataBagItem.load("passwords", instance['aws_credentials']).to_hash
    setenv_variables['AWS_ACCESS_KEY_ID'] = data_bag['access_key_id']
    setenv_variables['AWS_SECRET_ACCESS_KEY'] = data_bag['secret_access_key']
  end

  template setenv_file_path do
    cookbook 'tomcat'
    source 'setenv.sh.erb'
    owner user
    group group
    mode "0750"
    variables(
        :vars => setenv_variables
    )
    only_if { setenv_variables }
  end

  # Drop in a ServerInfo.properties (as described here: http://tomcat.apache.org/tomcat-7.0-doc/security-howto.html)
  # so as not to expose the tomcat version publicly.
  file server_info_properties do
    content  "server.info=Not specified\n"
    owner    user
    group    group
    mode     0644
    action   :create
  end

  # Setup log rotation on catalina.out for tomcat
  logrotate_app name  do
    cookbook  "logrotate"
    path      ::File.join(instance_dir, 'logs', 'catalina.out')
    frequency "daily"
  end

  service init_d_service do
    supports   :restart => true, :reload => true, :status => true
    action     :enable
    subscribes :restart, resources(
      "template[#{logging_properties}]",
      "template[#{server_xml}]",
      "template[#{init_d_service_path}]"
    ), :delayed
  end

end
