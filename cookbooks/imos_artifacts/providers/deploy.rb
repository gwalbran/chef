attr_reader :cached_file_path

action :deploy do
  artifact_manifest = {}
  if new_resource.artifact_manifest
    artifact_manifest = new_resource.artifact_manifest
  else
    artifact_manifest = Chef::EncryptedDataBagItem.load("imos_artifacts", new_resource.artifact_id)
  end
  @cached_file_path = ImosArtifactFetcher.new.fetch_artifact(artifact_manifest, node)
  deploy_artifact
end

def deploy_artifact
  install_dir = new_resource.install_dir
  dest_file = new_resource.file_destination

  Chef::Log.info("Attempting to deploy artifact '#{new_resource.name}' -> '#{install_dir}'")

  directory install_dir do
    user      new_resource.owner
    group     new_resource.group
    recursive true
  end

  if ArtifactDeployer.need_deploy?(dest_file, cached_file_path, install_dir)
    Chef::Log.info("Deploying artifact '#{cached_file_path}' -> '#{dest_file}' -> '#{install_dir}'")
    ArtifactDeployer.extract_artifact(
      cached_file_path,
      dest_file,
      install_dir,
      new_resource.owner,
      new_resource.group,
      new_resource.remove_top_level_directory)
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info("No need to deploy artifact '#{cached_file_path}' -> '#{dest_file}' -> '#{install_dir}'")
    new_resource.updated_by_last_action(false)
  end

end
