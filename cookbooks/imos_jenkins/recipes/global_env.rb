#
# Cookbook Name:: jenkins
# Recipe:: global_env
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Recipe to configure global environment
#

global_environment_groovy_code = ""
Chef::Recipe::JenkinsHelper.global_environment.each do |k, v|
  global_environment_groovy_code += "envVars.put(\"#{k}\", \"#{v}\")" + "\n"
end

jenkins_script 'set_global_properties' do
  command <<-EOH.gsub(/^ {4}/, '')
    import jenkins.model.*

    def instance = Jenkins.getInstance()
    def globalNodeProperties = instance.getGlobalNodeProperties()
    def envVarsNodePropertyList = globalNodeProperties.getAll(hudson.slaves.EnvironmentVariablesNodeProperty.class)

    def newEnvVarsNodeProperty
    def envVars
    if (envVarsNodePropertyList == null || envVarsNodePropertyList.size() == 0) {
        newEnvVarsNodeProperty = new hudson.slaves.EnvironmentVariablesNodeProperty();
        globalNodeProperties.add(newEnvVarsNodeProperty)
        envVars = newEnvVarsNodeProperty.getEnvVars()
    } else {
        envVars = envVarsNodePropertyList.get(0).getEnvVars()
    }

    #{global_environment_groovy_code}

    // Configure git username and email
    def gitExtension = instance.getExtensionList(hudson.plugins.git.GitSCM.DescriptorImpl.class)[0]
    gitExtension.setGlobalConfigName("#{node['imos_jenkins']['username']}")
    gitExtension.setGlobalConfigEmail("#{node['imos_jenkins']['email']}")

    // Set number of executors on master node
    instance.setNumExecutors(#{node['imos_jenkins']['executors'].to_i})

    instance.save()
  EOH
end

# Add the github.com key to known_hosts
execute "add-github-ssh-key" do
  command "su - #{node['imos_jenkins']['user']} -c 'ssh github.com -o StrictHostKeyChecking=no; true'"
  action  :run
  not_if  "su - #{node['imos_jenkins']['user']} -c 'test -f .ssh/known_hosts'"
end
