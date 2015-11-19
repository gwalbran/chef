define :cache_artifact do
  artifact_manifest = @params[:artifact_manifest]

  # Cache artifact, so we can use it to determine parallel deploy version
  artifact_metadata = ImosArtifacts::RemoteArtifact.get_metadata(artifact_manifest, node)
  artifact_manifest.merge! artifact_metadata

  imos_artifacts artifact_manifest['id'] do
    manifest artifact_manifest
    action :cache
  end

  artifact_manifest['cache_path']
end
