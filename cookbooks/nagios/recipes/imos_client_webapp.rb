#
# Cookbook Name:: nagios
# Recipe:: imos_client_webapp
#
# Copyright 2013, IMOS
#
# This recipe defines all the NRPE monitors for tomcat monitoring
#

# Check all IMOS tomcat instances
if node['webapps'] and node['webapps']['instances']
  node['webapps']['instances'].each do |webapp_instance|
    app_tomcat_port = webapp_instance['port']

    nagios_nrpecheck "check_tomcat_#{app_tomcat_port}" do
      command "#{node['nagios']['plugin_dir']}/check_http -H localhost -p #{app_tomcat_port}"
      action :add
    end

    jmx_remote_port = "#{node['tomcat']['jmx_remote_port_prefix']}#{app_tomcat_port}"

    # This plugin was sourced from: http://snippets.syabru.ch/nagios-jmx-plugin/
    nagios_nrpecheck "check_jmx_heap_mem_usage_#{app_tomcat_port}" do
      command "#{node['nagios']['plugin_dir']}/check_jmx/check_jmx"
      parameters "-U service:jmx:rmi:///jndi/rmi://localhost:#{jmx_remote_port}/jmxrmi -O 'java.lang:type=Memory' -A HeapMemoryUsage -K used -u B"
      action :add
    end

    webapp_instance['apps'].each do |webapp|
      webapp_name = webapp['name']

      webapp['jndis'].each do |jndi|
        resource = Chef::EncryptedDataBagItem.load('jndi_resources', jndi)['resource']

        nagios_nrpecheck "check_jmx_jndi_#{app_tomcat_port}_#{jndi}" do
          command "#{node['nagios']['plugin_dir']}/check_jmx/check_jmx"
          parameters "-U service:jmx:rmi:///jndi/rmi://localhost:#{jmx_remote_port}/jmxrmi -O 'Catalina:type=DataSource,context=/#{webapp_name},host=localhost,class=javax.sql.DataSource,name=\"#{resource}\"' -A maxIdle"
          action :add
        end
      end if webapp['jndis']
    end if webapp_instance['apps']

  end
end
