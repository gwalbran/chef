define :imos_tomcat_war do

  package "unzip"

  service_name = params[:service_name]

  # Temporarily store the extra_java_opts in the node so that it's accessible in the tomcat
  # recipe.  Trying to update/override the existing tomcat/instance/n/java_opts doesn't seem to be
  # possible for a mere mortal, as the instance array is being converted in to a hash (which
  # causes issues downstream).
  node.default['tomcat'][params[:tomcat_instance_name]]['extra_java_opts'] = params[:extra_java_opts]

  artifact_id        = params[:artifact_name] || params[:name]
  tomcat_webapps_dir = "#{node['tomcat']['base']}/#{params[:tomcat_instance_name]}/webapps"
  app_name           = params[:app_name] || artifact_id

  imos_artifacts_deploy artifact_id do
    install_dir      ::File.join(tomcat_webapps_dir, app_name)
    file_destination ::File.join(tomcat_webapps_dir, "#{app_name}.war")
    owner            node["tomcat"]["user"]
    group            node["tomcat"]["user"]
    notifies         :restart, "service[#{params[:service_name]}]", :delayed
  end

end
