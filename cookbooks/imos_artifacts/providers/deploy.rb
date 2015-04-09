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

def extract_artifact(artifact_src, artifact_dest, install_dir, owner, group)
  # Nuke install_dir if it exists
  if ::File.exists?(install_dir)
    FileUtils.rmtree install_dir
  end

  Dir.mktmpdir do |tmp_dir|
    # unzip to temporary directory
    %x{ unzip -q -u -o #{artifact_src} -d #{tmp_dir} }

    content_dir = tmp_dir

    # move contents of archive or top level directory in archive to install directory
    if new_resource.remove_top_level_directory
      content_dir = ::File.join(tmp_dir, top_level_dir(artifact_src))
      Chef::Log.info "Removing top level directory"
    end

    content_pathname = Pathname.new(content_dir)

    ::FileUtils.mkdir_p(install_dir)
    ::FileUtils.cp_r(content_pathname.children, install_dir)
    ::FileUtils.chown_R(owner, group, install_dir)
    
  end

  # Leave artifact in #{install_dir}/..
  ::FileUtils.cp(artifact_src, artifact_dest)
  ::FileUtils.chown(owner, group, artifact_dest)
end

def top_level_dir(artifact)
  zip_files = Mixlib::ShellOut.new("zipinfo -1 #{artifact}")
  zip_files.run_command
  first_file = zip_files.stdout.lines.first
  return first_file.split(::File::SEPARATOR)[0]
end

def deploy_artifact

  install_dir = new_resource.install_dir
  file_dest = new_resource.file_destination

  Chef::Log.info("Attempting to deploy IMOS artifact '#{new_resource.name}' -> '#{install_dir}'")

  directory install_dir do
    user      new_resource.owner
    group     new_resource.group
    recursive true
  end

  # this is the logic below in a nutshell:
  # file_dest file is different?
  #   deploy
  # destination directory doesn't exist or is empty?
  #   deploy
  # destination directory exist, but a new file was cached?
  #   deploy
  # else?
  #   don't deploy!!

  if !::File.exists?(file_dest) || (::File.exists?(file_dest) && !FileUtils.compare_file(cached_file_path, file_dest))
    Chef::Log.info("IMOS artifact at '#{file_dest}' is different than cached one, deploying...")
    extract_artifact(
      cached_file_path,
      file_dest,
      install_dir,
      new_resource.owner,
      new_resource.group)
    new_resource.updated_by_last_action(true)
  elsif !::File.exists?(install_dir) ||
    (::File.exists?(install_dir) && ::Dir["#{install_dir}/*"].empty?)
    Chef::Log.info("IMOS artifact directory does not exist, deploying...")
    extract_artifact(
      cached_file_path,
      file_dest,
      install_dir,
      new_resource.owner,
      new_resource.group)
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info("IMOS artifact was already cached, not unzipping.")
    new_resource.updated_by_last_action(false)
  end

end
