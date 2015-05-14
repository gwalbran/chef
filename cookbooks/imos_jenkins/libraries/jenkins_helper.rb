#
# Cookbook Name:: imos_jenkins
# Library:: jenkins_helper
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#

class Chef::Recipe::JenkinsHelper
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

  def self.groovy_code_for_pipeline(pipeline_databag)
    pipeline_name = pipeline_databag['id']
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

  private

  # A shell command to generate md5 for all artifacts
  def self.generate_md5_for_artifacts
    str  = '#!/bin/bash' + "\n"
    str += 'for i in `find . -regex "^\./.*\(war\|jar\|zip\)$"`; do echo "$i"; md5sum "$i" > "$i.md5"; done'
    return str
  end
end
