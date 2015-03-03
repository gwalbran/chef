def cache_path
  File.join(Chef::Config[:file_cache_path], "jenkins")
end

# Directory to store job templates
directory cache_path

data_bag('build_jobs').each do |item_id|
  artifact_databag_item = Chef::DataBagItem.load('build_jobs', item_id)

  jenkins_variables = artifact_databag_item.to_hash.dup

  # Jenkins specific stuff under the 'jenkins' variable
  jenkins_variables.merge!(artifact_databag_item['jenkins'].dup)

  jenkins_variables['variables']['description'] = "" # Must set description
  if artifact_databag_item['description']
    jenkins_variables['variables']['description'] = artifact_databag_item['description']
  end

  job_name = jenkins_variables['id']
  Chef::Log.info("Configuring Jenkins CI for '#{job_name}'")

  job_template_cache = File.join(cache_path, "#{job_name}.xml")
  template job_template_cache do
    source    jenkins_variables['template']
    cookbook  jenkins_variables['cookbook']
    variables jenkins_variables['variables']
  end

  jenkins_job job_name do
    config job_template_cache
  end
end
