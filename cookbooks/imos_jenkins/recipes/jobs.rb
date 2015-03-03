imos_artifacts = data_bag('imos_artifacts')

def has_ci_config(artifact)
  artifact.key?('ci')
end

imos_artifacts.each do |item_id|

  artifact_databag_item = Chef::EncryptedDataBagItem.load('imos_artifacts', item_id)

  if has_ci_config(artifact_databag_item)
    artifact_id = artifact_databag_item['id']
    Chef::Log.info("Configuring CI for artifact #{artifact_id}...")

    build_and_test_config_xml = File.join(Chef::Config[:file_cache_path], "#{artifact_id}_build_and_test_config.xml")
    template build_and_test_config_xml do
      source 'jobs/build_and_test_config.xml.erb'
      variables(
        :repository_url => artifact_databag_item['ci']['repository']['url']
      )
    end

    jenkins_job "#{artifact_id}_build_and_test" do
      config build_and_test_config_xml
    end
  end
end
