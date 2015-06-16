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

  # Assume jenkins job is given if data bag is not available
  artifact_manifest = ArtifactDeployer.get_artifact_manifest(artifact_name)

  app_deploy_name = app_name
  service_notify_action = :restart

  # Cache artifact, so we can use it to determine parallel deploy version
  cached_artifact = ImosArtifactFetcher.new.fetch_artifact(artifact_manifest, node)

  if params[:parallel_deploy]
    version = ParallelDeploy.tomcat_version_for_artifact(cached_artifact)
    app_deploy_name = ParallelDeploy.add_version(app_name, version)
    context_file = File.join(context_dir, "#{app_deploy_name}.xml")
    Chef::Log.info("Invoking parallel deploy with version: '#{version}'")

    # Disable restarts if using parallel_deploy
    service_notify_action = :nothing
  end

  file_destination = ::File.join(tomcat_webapps_dir, "#{app_deploy_name}.war")
  install_dir = ::File.join(tomcat_webapps_dir, app_deploy_name)
  Chef::Log.info("Deploying: '#{file_destination}' -> '#{install_dir}'")

  imos_artifacts_deploy artifact_name do
    install_dir       install_dir
    file_destination  file_destination
    artifact_manifest artifact_manifest
    owner             node["tomcat"]["user"]
    group             node["tomcat"]["user"]
    notifies          service_notify_action, "service[#{service_name}]", :delayed
    cached_artifact   cached_artifact
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
    notifies  service_notify_action, "service[#{service_name}]", :delayed
    variables (params[:template_variables])
  end

end
