#
# Cookbook Name:: imos_artifacts
# Provider:: deploy
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Provider to deploy artifacts
#

action :deploy do
  cached_file_path = nil

  if new_resource.cached_artifact
    cached_file_path = new_resource.cached_artifact
  else
    artifact_manifest = new_resource.artifact_manifest
    cached_file_path = cache_artifact do
      artifact_manifest artifact_manifest
    end
  end

  install_dir = new_resource.install_dir
  dest_file = new_resource.file_destination

  Chef::Log.info("Attempting to deploy artifact '#{new_resource.name}' -> '#{install_dir}'")

  directory install_dir do
    user      new_resource.owner
    group     new_resource.group
    recursive true
  end

  ruby_block 'deploy_if_necessary' do
    block do
      if ::ImosArtifacts::Deployer.need_deploy?(dest_file, cached_file_path, install_dir)
        Chef::Log.info("Deploying artifact '#{cached_file_path}' -> '#{dest_file}' -> '#{install_dir}'")
        ::ImosArtifacts::Deployer.extract_artifact(
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
  end
end
