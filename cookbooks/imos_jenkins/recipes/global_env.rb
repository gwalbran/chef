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

global_environment = Chef::Recipe::JenkinsHelper.global_environment
global_environment['S3CMD_CONFIG'] = node['imos_jenkins']['s3cmd']['config_file']

global_environment_groovy_code = ""
global_environment.each do |k, v|
  global_environment_groovy_code += "envVars.put(\"#{k}\", \"#{v}\")" + "\n"
end

if !Chef::Config[:dev]
  global_environment_groovy_code += <<-EOH

  // Set main URL
  def jenkinsLocationConfiguration = JenkinsLocationConfiguration.get()
    jenkinsLocationConfiguration.setUrl("#{node['imos_jenkins']['master_url']}")
    jenkinsLocationConfiguration.save()

  EOH
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

    // Set port for slaves to connect to
    instance.setSlaveAgentPort(#{node['imos_jenkins']['ajp_port'].to_i})

    instance.save()
  EOH
end

# Add the github.com key to known_hosts
execute "add-github-ssh-key" do
  command "su - #{node['imos_jenkins']['user']} -c 'ssh github.com -o StrictHostKeyChecking=no; true'"
  action  :run
  not_if  "su - #{node['imos_jenkins']['user']} -c 'test -f .ssh/known_hosts'"
end
