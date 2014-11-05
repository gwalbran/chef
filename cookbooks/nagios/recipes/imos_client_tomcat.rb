#
# Cookbook Name:: nagios
# Recipe:: imos_client_tomcat
#
# Copyright 2013, IMOS
#
# This recipe defines all the NRPE monitors for tomcat monitoring
#

# Check all IMOS tomcat instances
if node['tomcat'] && node['tomcat']['instances']
  node['tomcat']['instances'].each do |tomcat_instance|
    instance_name = tomcat_instance['name']
    instance_port = tomcat_instance['ports']['connector_port'] ? tomcat_instance['ports']['connector_port'] : 8080

    # Make sure it's an actual tomcat instance and not the stub one taken
    # from the cookbook's attributes
    if instance_name != "default" && instance_port != "8080"

      nagios_nrpecheck "check_tomcat_#{instance_port}" do
        command "#{node['nagios']['plugin_dir']}/check_http -H localhost -p #{instance_port}"
        action :add
      end

      # restart handler for tomcat
      nagios_nrpecheck "restart_tomcat_#{instance_port}" do
        command "sudo -u root #{node['nagios']['plugin_dir']}/restart_tomcat -n #{instance_name} -p #{instance_port}"
        action :add
      end

      # restart_tomcat will need to run as root
      sudo "nagios_restart_tomcat" do
        user node['nagios']['user']
        runas "root"
        commands [ "#{node['nagios']['plugin_dir']}/restart_tomcat" ]
        host "ALL"
        nopasswd true
      end

    end
  end
end


