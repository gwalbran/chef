class ArtifactDeployer

  def self.extract_artifact(artifact_src, artifact_dest, install_dir, owner, group, remove_top_level_directory = false)
    # Nuke install_dir if it exists
    if ::File.exists?(install_dir)
      FileUtils.rmtree install_dir
    end

    Dir.mktmpdir do |tmp_dir|
      # unzip to temporary directory
      %x{ unzip -q -u -o #{artifact_src} -d #{tmp_dir} }

      content_dir = tmp_dir

      # move contents of archive or top level directory in archive to install directory
      if remove_top_level_directory
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

  def self.top_level_dir(artifact)
    zip_files = Mixlib::ShellOut.new("zipinfo -1 #{artifact}")
    zip_files.run_command
    first_file = zip_files.stdout.lines.first
    return first_file.split(::File::SEPARATOR)[0]
  end

  def self.need_deploy?(dest_file, cached_file, install_dir)
    if !::File.exists?(dest_file)
      # destination file doesn't exist - DEPLOY!
      return true
    elsif ::File.exists?(dest_file) && !FileUtils.compare_file(cached_file, dest_file)
      # destination file exists but cached file is newer - DEPLOY!
      return true
    elsif !::File.exists?(install_dir)
      # installation dir doesn't exist - DEPLOY!
      return true
    elsif ::File.exists?(install_dir) && ::Dir["#{install_dir}/*"].empty?
      # installation dir exists and is empty - DEPLOY!
      return true
    else
      # alright, everything is in place - no need to deploy
      return false
    end
  end

end
