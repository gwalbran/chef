define :delete_tomcat_instance do
  instance_name  = @params[:name]

  # Stop
  service "tomcat_#{instance_name}" do
    service_name "tomcat_#{instance_name}"
    action [:stop, :disable]
  end

  # Delete init.d scripts.
  file "/etc/init.d/tomcat_#{instance_name}" do
    action :delete
  end

  # Delete /var/lib/tomcat7/* not in list
  directory "#{node['tomcat']['base']}/#{instance_name}" do
    recursive true
    action :delete
  end

end
