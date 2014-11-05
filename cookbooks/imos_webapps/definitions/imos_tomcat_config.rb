define :imos_tomcat_config do

  artifact_name       = @params[:artifact_name]
  app_name            = @params[:app_name]
  config_template_dir = @params[:config_template_dir]
  config_file         = @params[:config_file_name]
  base_directory      = @params[:base_directory]
  service_name        = @params[:service_name]
  config_dir          = File.join(base_directory, "conf", app_name)
  context_dir         = File.join(base_directory, "conf", "Catalina", "localhost")
  context_file        = File.join(context_dir, "#{app_name}.xml")

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
