define :tomcat_instance do
  name            = @params[:name]
  instance        = @params[:instance]
  port            = instance['port']
  java_opts       = instance['java_options'] || node['tomcat']['java_options']
  parallel_deploy = instance['parallel_deploy']
  admin_port      = @params[:admin_port] || "1#{port}"

  fetcher = ImosArtifactFetcher.new

  artifact_manifest = Chef::EncryptedDataBagItem.load("imos_artifacts", "tomcat-#{node['tomcat']['fine_version'].tr('.', '-')}")
  cache_file_path, artifact_downloaded = fetcher.fetch_artifact(artifact_manifest, node)

  tomcat_version   = node['tomcat']['version']
  tomcat_log_level = node['tomcat']['log_level']

  instance_dir = "#{node['tomcat']['base']}/#{name}"

  jmx_remote_port = "#{node['tomcat']['jmx_remote_port_prefix']}#{port}"
  java_opts += " #{node['tomcat']['jmx_options'] % jmx_remote_port}"

  log "Installing tomcat instance #{name} to #{instance_dir}..."

  user = node[:tomcat][:user]

  # Create directory for each instance.
  directory instance_dir do
    owner user
    group user
    recursive true
    mode 00755
  end

  # Extract tomcat tarball in to each directory.
  bash "extract tomcat for #{name}"  do
    cwd instance_dir
    user "root"
    code <<-EOH
      tar xzf #{cache_file_path}
      cd apache-tomcat-#{node['tomcat']['fine_version']}/webapps
      rm -rf examples docs host-manager manager
      cd ../..
      cp -rf apache-tomcat-#{node['tomcat']['fine_version']}/* .
      rm -rf apache-tomcat-#{node['tomcat']['fine_version']}
      chown -R #{user}:#{user} *
    EOH
    not_if { File.directory?("#{instance_dir}/bin") }
  end

  # Create init.d script for each instance.
  template "/etc/init.d/tomcat#{tomcat_version}_#{name}" do
    cookbook "tomcat"
    source "tomcat#{tomcat_version}.erb"
    owner "root"
    group "root"
    mode 00755
    variables(
        :name => name,
        :java_opts => java_opts
    )
  end

  template "#{instance_dir}/conf/server.xml" do
    cookbook "tomcat"
    source "server_tomcat#{tomcat_version}.xml.erb"
    owner user
    group user
    mode "0644"
    variables(
        :instance => instance,
        :ports => { :connector_port => port, :port => admin_port },
        :parallel_deploy => parallel_deploy
    )
  end

  template "#{instance_dir}/conf/logging.properties" do
    cookbook "tomcat"
    source "logging_properties.xml.erb"
    owner user
    group user
    mode "0644"
    variables(
        :level => tomcat_log_level
    )
  end

  # Drop in a ServerInfo.properties (as described here: http://tomcat.apache.org/tomcat-7.0-doc/security-howto.html)
  # so as not to expose the tomcat version publicly.
  server_info_properties_dir = File.join(instance_dir, "lib", "org", "apache", "catalina", "util")
  server_info_properties     = File.join(server_info_properties_dir, "ServerInfo.properties")

  directory server_info_properties_dir do
    owner      node['tomcat']['user']
    group      node['tomcat']['user']
    mode       0755
    recursive  true
    action     :create
  end

  cookbook_file server_info_properties do
    cookbook "tomcat"
    owner    node['tomcat']['user']
    group    node['tomcat']['user']
    mode     0644
    action   :create
  end

  # Setup log rotation on catalina.out for tomcat
  logrotate_app name  do
    cookbook "logrotate"
    path "#{instance_dir}/logs/catalina.out"
    frequency "daily"
  end

  service "tomcat#{tomcat_version}_#{name}" do
    case node["platform"]
      when "centos","redhat","fedora"
        supports :restart => true, :status => true
      when "debian","ubuntu"
        supports :restart => true, :reload => true, :status => true
    end
    action :enable
    subscribes :restart, resources("template[#{instance_dir}/conf/logging.properties]", "template[#{instance_dir}/conf/server.xml]", "template[/etc/init.d/tomcat#{tomcat_version}_#{name}]"), :delayed
  end

end
