#
# Cookbook Name:: tomcat
# Recipe:: unmanaged_tomcat
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

include_recipe "tomcat::default"

# Cleanup previous installations which are no longer in the instance list.
instance_names = node['tomcat']['instances'].map { |instance| instance['name'] }
curr_instances = File.exist?(node['tomcat']['base']) ? Dir.entries(node['tomcat']['base']).select { |dir_name| dir_name != '.' && dir_name != '..' } : []
instances_to_delete = curr_instances - instance_names
tomcat_log_level = node['tomcat']['log_level']

instances_to_delete.each do |instance_name|

  # Stop
  service "tomcat#{tomcat_version}_#{instance_name}" do
    service_name "tomcat#{tomcat_version}_#{instance_name}"
    action [:stop, :disable]
  end

  # Delete init.d scripts.
  file "/etc/init.d/tomcat#{tomcat_version}_#{instance_name}" do
    action :delete
  end

  # Delete /var/lib/tomcat7/* not in list
  directory "#{node['tomcat']['base']}/#{instance_name}" do
    recursive true
    action :delete
  end

end

fetcher = ImosArtifactFetcher.new

cache_file_path, artifact_downloaded = fetcher.fetch_artifact("tomcat-#{node['tomcat']['fine_version'].tr('.', '-')}", node)

node[:tomcat][:instances].each_with_index do |instance, index|

  instance_dir = "#{node['tomcat']['base']}/#{instance[:name]}"

  log "Installing tomcat instance #{instance[:name]} to #{instance_dir}..."

  user = node[:tomcat][:user]

  # Create directory for each instance.
  directory instance_dir do
    owner user
    group user
    recursive true
    mode 00755
  end

  # Extract tomcat tarball in to each directory.
  bash "extract tomcat for #{instance['name']}"  do
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

  # This will only have an effect if ports haven't been specified in the node/json file (which is
  # not the case for all of our production nodes).

  newPorts = Mash.new
  node[:tomcat][:ports].each do |port_name, base_port_number|
    newPorts[port_name] = instance[:ports][port_name] || "#{index + 1}#{base_port_number}"
  end

  java_opts = instance['java_options'] || node['tomcat']['java_options']
  java_opts = "#{java_opts} #{node['tomcat'][instance['name']]['extra_java_opts']}" if node['tomcat'][instance['name']]

  # Create init.d script for each instance.
  template "/etc/init.d/tomcat#{tomcat_version}_#{instance['name']}" do
    source "tomcat#{tomcat_version}.erb"
    owner "root"
    group "root"
    mode 00755
    variables(
        :name => instance['name'],
        :java_opts => java_opts
    )
  end

  template "#{instance_dir}/conf/server.xml" do
    source "server_tomcat#{tomcat_version}.xml.erb"
    owner user
    group user
    mode "0644"
    variables(
        :instance => instance,
        :ports    => newPorts,
        :index    => index
    )
  end

  template "#{instance_dir}/conf/logging.properties" do
    source "logging_properties.xml.erb"
    owner user
    group user
    mode "0644"
    variables(
        :level => tomcat_log_level
    )
  end

  # Setup log rotation on catalina.out for tomcat
  logrotate_app "#{instance['name']}"  do
    cookbook "logrotate"
    path "#{instance_dir}/logs/catalina.out"
    options [ "copytruncate", "missingok", "delaycompress", "notifempty"]
    frequency "daily"
    rotate 2
    size 20000000
  end

  service "tomcat#{tomcat_version}_#{instance['name']}" do
    case node["platform"]
      when "centos","redhat","fedora"
        supports :restart => true, :status => true
      when "debian","ubuntu"
        supports :restart => true, :reload => true, :status => true
    end
    action :enable
    subscribes :restart, resources("template[#{instance_dir}/conf/logging.properties]", "template[#{instance_dir}/conf/server.xml]"), :delayed
  end
end
