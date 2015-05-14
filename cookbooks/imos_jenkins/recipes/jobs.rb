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

def jenkins_pipeline(pipeline_databag)
  jenkins_view pipeline_databag['id'] do
    code Chef::Recipe::JenkinsHelper.groovy_code_for_pipeline(pipeline_databag)
  end
end

jenkins_jobs = {}

data_bag('build_jobs').each do |item_id|
  job_databag = Chef::DataBagItem.load('build_jobs', item_id)
  job_name = job_databag['id']

  # Merge variables in the following order:
  # * Predefined variables
  # * Variables from template (if exists)
  # * Data bag variables

  templated_variables = get_templated_variables_for_job(job_name, job_databag['template'])
  jenkins_variables = Chef::Recipe::JenkinsHelper.merge_hashes(
    Chef::Recipe::JenkinsHelper.predefined_variables,
    templated_variables,
    job_databag.to_hash
  )

  # Skip jobs marked as templates
  if ! job_databag['is_template']
    jenkins_jobs[job_name] = jenkins_variables
  end
end

# Deal with job pipelines
data_bag('build_pipelines').each do |pipeline_id|
  Chef::Log.info("Configuring Jenkins pipeline for '#{pipeline_id}'")

  downstream_project = nil

  pipeline_databag = Chef::DataBagItem.load('build_pipelines', pipeline_id)
  # Iterate reverse
  pipeline_databag['jobs'].reverse_each do |job_item|
    job_name = "#{pipeline_id}_#{job_item['name']}"

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
        "properties" => "ARTIFACT_BUILD_NUMBER=$BUILD_NUMBER",
        "downstream_project" => downstream_project
      }]
      if job_item['auto_trigger_next']
        jenkins_variables['downstream_projects'] = downstream_projects
      else
        jenkins_variables['downstream_pipeline_projects'] = downstream_projects
      end
    end

    jenkins_jobs[job_name] = jenkins_variables

    downstream_project = job_name
  end

  jenkins_pipeline(pipeline_databag)
end

# Directory to store job templates
directory cache_path

jenkins_jobs.each do |job_name, variables|
  Chef::Log.info("Configuring Jenkins CI for '#{job_name}'")

  job_template_cache = File.join(cache_path, "#{job_name}.xml")
  Chef::Log.info("Cache file for '#{job_name}' at '#{job_template_cache}'")

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
