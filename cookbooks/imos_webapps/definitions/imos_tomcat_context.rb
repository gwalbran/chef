define :imos_tomcat_context do
  artifact_name       = @params[:name]
  app_name            = @params[:app_name]
  config_template_dir = @params[:config_template_dir]
  config_file         = @params[:config_file_name]
  base_directory      = ::File.join(node['tomcat']['base'], @params[:tomcat_instance_name])
  service_name        = @params[:service_name]
  config_dir          = File.join(base_directory, "conf", app_name)
  context_dir         = File.join(base_directory, "conf", "Catalina", "localhost")
  context_file        = File.join(context_dir, "#{app_name}.xml")
  tomcat_webapps_dir = ::File.join(base_directory, "webapps")

  artifact_manifest = {}
  begin
    artifact_manifest = Chef::EncryptedDataBagItem.load("imos_artifacts", artifact_name).to_hash
  rescue
    Chef::Log.info("Building artifact manifest for '#{artifact_name}'")
    artifact_manifest = { 'id' => artifact_name, 'job' => artifact_name }
  end

  service_notify_action = :restart
  if params[:parallel_deploy]
    service_notify_action = :nothing
  end

  imos_artifacts_deploy artifact_name do
    install_dir       ::File.join(tomcat_webapps_dir, app_name)
    file_destination  ::File.join(tomcat_webapps_dir, "#{app_name}.war")
    artifact_manifest artifact_manifest
    owner             node["tomcat"]["user"]
    group             node["tomcat"]["user"]
    parallel_deploy   params[:parallel_deploy]
    notifies          service_notify_action, "service[#{params[:service_name]}]", :delayed
  end

  # Main config file
  directory config_dir do
    owner  node['tomcat']['user']
    group  node['tomcat']['user']
    mode   0755
    action :create
  end

  if config_file
    template "#{config_dir}/#{config_file}" do
      source    "#{config_template_dir}/#{config_file}.erb"
      owner     node['tomcat']['user']
      group     node['tomcat']['user']
      mode      0644
      notifies  :restart, "service[#{service_name}]", :delayed
      variables (params[:template_variables])
    end
  end

  # Context file
  directory context_dir do
    owner     node['tomcat']['user']
    group     node['tomcat']['user']
    recursive true
  end

  # Inject config_dir and config_file, so context file can use those
  params[:template_variables][:config_dir]  = config_dir
  params[:template_variables][:config_file] = config_file

  # Context file (where JNDI resources are defined)
  template context_file do
    source    "context.xml.erb"
    owner     node['tomcat']['user']
    group     node['tomcat']['user']
    mode      0644
    notifies  :restart, "service[#{service_name}]", :delayed
    variables (params[:template_variables])
  end

end
