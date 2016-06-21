#
# Cookbook Name:: imos_jenkins
# Library:: jenkins_helper
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#

require 'openssl'
require 'net/ssh'

class Chef::Recipe::JenkinsHelper

  def self.get_key_pair
    ssh_private_key = Chef::EncryptedDataBagItem.load("users", "chef")['ssh_private_key']
    key = OpenSSL::PKey::RSA.new(ssh_private_key)
    private_key = key.to_pem
    public_key = "#{key.ssh_type} #{[key.to_blob].pack('m0')}"
    return { :private_key => private_key, :public_key => public_key }
  end

  def self.set_jenkins_creds(node)
    # Set the private key on the Jenkins executor
    private_key = get_key_pair()[:private_key]
    node.run_state[:jenkins_private_key] = private_key
  end

  def self.authenticate(node)
    set_jenkins_creds node
  end

  # Merge all given hashes into one hash
  def self.merge_hashes(*hashes)
    retval = {}
    hashes.each do |hash|
      hash and retval.merge!(hash)
    end
    return retval
  end

  # Return a hash of predefined Jenkins variables
  def self.predefined_variables
    variables = {}
    variables['generate_md5_for_artifacts'] = self.generate_md5_for_artifacts
    return variables
  end

  # Groovy code for installing common tools such as ant, grails, maven
  def self.groovy_code_for_tool_installer(versions, namespace, extension_class, installer_class, installation_class)
    extension_class = "#{namespace}.#{extension_class}"
    installation_class = "#{namespace}.#{installation_class}"
    installer_class = "#{namespace}.#{installer_class}"
    return <<-GROOVY
      import jenkins.model.*
      import hudson.tools.InstallSourceProperty

      def requiredToolVersions = #{versions}

      def extensions = Jenkins.instance.getExtensionList(#{extension_class}.DescriptorImpl.class)[0]
      def toolInstallations = (extensions.installations as List)

      def installedToolVersions = toolInstallations.collect { it.getName() }

      def toolVersionsToInstall = requiredToolVersions - installedToolVersions

      if (!toolVersionsToInstall.isEmpty()) {
        def newToolInstallations = toolInstallations
        toolVersionsToInstall.each { toolVersion ->
          println "Installing ${toolVersion}"
          def toolAutoInstaller = new #{installer_class}(toolVersion)
          def installProperty = new InstallSourceProperty([toolAutoInstaller])
          def autoInstallation = new #{installation_class}(toolVersion, "", [installProperty])
          newToolInstallations.add(autoInstallation)
        }
        extensions.installations = newToolInstallations
        extensions.save()
      }
    GROOVY
  end

  def self.groovy_code_for_pipeline(app_id, pipeline_databag)
    pipeline_name = app_id
    first_job = "#{pipeline_name}_#{pipeline_databag['jobs'].first['name']}"

    return <<-GROOVY
import au.com.centrumsystems.hudson.plugin.buildpipeline.*

def viewName = '#{pipeline_name}'
def buildViewTitle = '#{pipeline_name}'
def cssUrl = ""
def triggerOnlyLatestJob = #{pipeline_databag['trigger_only_latest_job'].nil? ? false : pipeline_databag['trigger_only_latest_job']}
def alwaysAllowManualTrigger = #{pipeline_databag['always_allow_manual_trigger'].nil? ? true : pipeline_databag['always_allow_manual_trigger']}
def showPipelineParameters = #{pipeline_databag['show_pipeline_parameters'].nil? ? true : pipeline_databag['show_pipeline_parameters']}
def showPipelineParametersInHeaders = #{pipeline_databag['show_pipeline_parameters_in_headers'].nil? ? true : pipeline_databag['show_pipeline_parameters_in_headers']}
def startsWithParameters = #{pipeline_databag['starts_with_parameters'].nil? ? false : pipeline_databag['starts_with_parameters']}
def refreshFrequency = 3
def showPipelineDefinitionHeader = true
def noOfDisplayedBuilds = "#{pipeline_databag['displayed_builds'] || 10}"
def gridBuilder = new DownstreamProjectGridBuilder('#{first_job}')

create_view = { name ->
  return new BuildPipelineView(
    viewName,
    buildViewTitle,
    gridBuilder,
    noOfDisplayedBuilds,
    triggerOnlyLatestJob,
    cssUrl
  )
}

configure_view = { view ->
  view.setGridBuilder(gridBuilder)
  view.setBuildViewTitle(buildViewTitle)
  view.setCssUrl(cssUrl)
  view.setNoOfDisplayedBuilds(noOfDisplayedBuilds)
  view.setTriggerOnlyLatestJob(triggerOnlyLatestJob)
  view.setAlwaysAllowManualTrigger(alwaysAllowManualTrigger)
  view.setShowPipelineParameters(showPipelineParameters)
  view.setShowPipelineParametersInHeaders(showPipelineParametersInHeaders)
  view.setShowPipelineDefinitionHeader(showPipelineDefinitionHeader)
}
GROOVY
  end

  def self.java_home
    ::File.realpath('/usr/bin/java').gsub('/jre/bin/java', '')
  end

  def self.global_environment
    return {
      :JAVA_HOME => self.java_home
    }
  end

  private

  # A shell command to generate md5 for all artifacts
  def self.generate_md5_for_artifacts
    str  = '#!/bin/bash' + "\n"
    str += 'for i in `find . -type f -regex "^\./.*\(war\|jar\|zip\|egg\)$"`; do echo "$i"; md5sum "$i" > "$i.md5"; done'
    return str
  end
end
