#
# Cookbook Name:: jenkins
# Recipe:: global_env
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Recipe to configure global environment variables
#

def canonicalized_path(path)
  path = '/usr/bin/java'
  while ::File.symlink?(path)
    path = ::File.readlink(path)
  end
  path.chomp
end

def java_home
  canonicalized_path('/usr/bin/java').gsub('/jre/bin/java', '')
end

global_environment = {
  :JAVA_HOME => java_home
}

global_environment_groovy_code = ""
global_environment.each do |k, v|
  global_environment_groovy_code += "envVars.put(\"#{k}\", \"#{v}\")" + "\n"
end

jenkins_script 'set_global_properties' do
  command <<-EOH.gsub(/^ {4}/, '')
    import jenkins.model.*

    instance = Jenkins.getInstance()
    globalNodeProperties = instance.getGlobalNodeProperties()
    envVarsNodePropertyList = globalNodeProperties.getAll(hudson.slaves.EnvironmentVariablesNodeProperty.class)

    if (envVarsNodePropertyList == null || envVarsNodePropertyList.size() == 0) {
        newEnvVarsNodeProperty = new hudson.slaves.EnvironmentVariablesNodeProperty();
        globalNodeProperties.add(newEnvVarsNodeProperty)
        envVars = newEnvVarsNodeProperty.getEnvVars()
    } else {
        envVars = envVarsNodePropertyList.get(0).getEnvVars()
    }

    #{global_environment_groovy_code}

    instance.save()
  EOH
end

# Add the github.com key to known_hosts
execute "add-github-ssh-key" do
  command "su - #{node['imos_jenkins']['user']} -c 'ssh github.com -o StrictHostKeyChecking=no; true'"
  action  :run
  not_if  "su - #{node['imos_jenkins']['user']} -c 'test -f .ssh/known_hosts'"
end
