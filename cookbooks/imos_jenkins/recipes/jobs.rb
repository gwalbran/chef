#
# Cookbook Name:: jenkins
# Recipe:: jobs
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Manages jobs, views and pipelines on Jenkins
#

def cache_path
  File.join(Chef::Config[:file_cache_path], "jenkins")
end

def get_templated_variables_for_job(job_name, job_template)
  if job_template
    Chef::Log.info("Jenkins '#{job_name}' uses template '#{job_template}'")
    return Chef::DataBagItem.load('build_jobs', job_template).to_hash
  elsif ! Chef::Search::Query.new.search('build_jobs', "id:#{job_name}").empty? # if data bag exists
    # In the case where a job_template is not defined, do not fail in case
    # a data bag with the corresponding job_name does not exist
    Chef::Log.info("Jenkins '#{job_name}' uses template '#{job_name}'")
    return Chef::DataBagItem.load('build_jobs', job_name).to_hash
  else
    return {}
  end
end

def jenkins_pipepline_for_app(app_id, pipeline_databag)
  Chef::Log.info("Configuring Jenkins '#{pipeline_databag['id']}' pipeline for '#{app_id}' app...")

  downstream_project = nil

  # Iterate reverse
  pipeline_databag['jobs'].reverse_each do |job_item|
    job_name = "#{app_id}_#{job_item['name']}"

    # Merge variables in the following order:
    # * Predefined variables
    # * Variables from job suffix name (such as `set_version` data bag)
    # * Variables in this actual build_pipeline data bag
    # * Variables in specific jobs in build_pipeline data bag

    templated_variables = get_templated_variables_for_job(job_name, job_item['template'])
    jenkins_variables = Chef::Recipe::JenkinsHelper.merge_hashes(
      Chef::Recipe::JenkinsHelper.predefined_variables,
      templated_variables,
      pipeline_databag,
      job_item
    )

    if downstream_project
      downstream_projects = [{
        "properties" => { "ARTIFACT_BUILD_NUMBER" => "$BUILD_NUMBER" },
        "downstream_project" => downstream_project
      }]
      if job_item['auto_trigger_next']
        jenkins_variables['downstream_projects'] = downstream_projects
      else
        jenkins_variables['downstream_pipeline_projects'] = downstream_projects
      end
    end

    @jenkins_jobs[job_name] = jenkins_variables

    downstream_project = job_name
  end

  # set upstream project
  upstream_project = nil
  pipeline_databag['jobs'].each do |job_item|

    job_name = "#{app_id}_#{job_item['name']}"

    if upstream_project
      @jenkins_jobs[job_name]['upstream_project'] = upstream_project
    end

    upstream_project = job_name
  end

  imos_jenkins_view app_id do
    code Chef::Recipe::JenkinsHelper.groovy_code_for_pipeline(app_id, pipeline_databag)
  end
end

def jenkins_pipeline(pipeline_databag)
  if pipeline_databag['apps']
    pipeline_databag['apps'].each do |app_id|
      jenkins_pipepline_for_app(app_id, pipeline_databag)
    end
  elsif
    jenkins_pipepline_for_app(pipeline_databag['id'], pipeline_databag)
  end
end

@jenkins_jobs = {}

# Deal with job pipelines
data_bag('build_pipelines').each do |pipeline_id|
  pipeline_databag = Chef::DataBagItem.load('build_pipelines', pipeline_id)
  jenkins_pipeline(pipeline_databag)
end

data_bag('build_jobs').each do |item_id|
  job_databag = Chef::DataBagItem.load('build_jobs', item_id)
  job_name = job_databag['id']

  # Merge variables in the following order:
  # * Predefined variables
  # * Variables from template (if exists)
  # * Variables from pipeline config (if exists)
  # * Data bag variables

  templated_variables = get_templated_variables_for_job(job_name, job_databag['template'])
  jenkins_variables = Chef::Recipe::JenkinsHelper.merge_hashes(
    Chef::Recipe::JenkinsHelper.predefined_variables,
    templated_variables,
    @jenkins_jobs[job_name],
    job_databag.to_hash
  )

  # Skip jobs marked as templates
  if ! job_databag['is_template']
    @jenkins_jobs[job_name] = jenkins_variables
  end
end

# Directory to store job templates
directory cache_path

@jenkins_jobs.each do |job_name, variables|
  Chef::Log.info("Configuring Jenkins CI for '#{job_name}'")

  job_template_cache = File.join(cache_path, "#{job_name}.xml")
  Chef::Log.info("Cache file for '#{job_name}' at '#{job_template_cache}'")

  variables['publishing_enabled'].nil? and variables['publishing_enabled'] = true
  variables['job_enabled'].nil? and variables['job_enabled'] = true
  if Chef::Config[:dev]
    variables['job_enabled'] = false
    variables['publishing_enabled'] = false
  end

  template job_template_cache do
    source    variables['job_template']
    cookbook  variables['job_cookbook']
    variables variables
    notifies  :create, "jenkins_job[#{job_name}]", :immediately
  end

  jenkins_job job_name do
    config job_template_cache
    action :nothing
  end
end

# TODO delete unnecessary jobs

# Create views
data_bag('build_views').each do |item_id|
  view_databag = Chef::DataBagItem.load('build_views', item_id)
  jobs = []
  view_databag['jobs'].each do |job|
    Chef::Search::Query.new.search('build_jobs', "id:#{job}").each do |item|
      item['is_template'] != true and jobs << item['id']
    end
  end

  action = :create
  if jobs.empty?
    Chef::Log.warn "Deleting Jenkins view '#{view_databag['id']}' as it has no items in it"
    action = :delete
  end

  imos_jenkins_view view_databag['id'] do
    jobs   jobs
    action action
  end
end

public_jenkins_jobs = []
@jenkins_jobs.each do |job_name, variables|
  if variables['private']
    Chef::Log.info("Jenkins job '#{job_name}' is private - not exposing")
  else
    Chef::Log.info("Jenkins job '#{job_name}' is public")
    public_jenkins_jobs << job_name
  end
end

jenkins_script 'public jobs authorization' do
  command <<-EOH.gsub(/^ {4}/, '')
    import jenkins.model.*
    import hudson.security.*
    import com.michelin.cio.hudson.plugins.rolestrategy.*

    def publicJobs = #{public_jenkins_jobs}

    def addPublicAccess(strategy, jobName) {
        // Grant only read access only to jobs matching pattern
        permissions = new HashSet<Permission>()
        permissions.add(PermissionGroup.get(hudson.model.Item).find("Read"))

        def jobRegex = '^' + jobName + '$' // Exact regex matching
        def jobRole = new Role(jobName, jobRegex, permissions)
        strategy.addRole(strategy.PROJECT, jobRole)
        strategy.assignRole(strategy.PROJECT, jobRole, "anonymous")
    }

    def instance = Jenkins.getInstance()
    def strategy = instance.getAuthorizationStrategy()

    publicJobs.each { jobName ->
        addPublicAccess(strategy, jobName)
    }

    instance.setAuthorizationStrategy(strategy)
    instance.save()
  EOH
end
