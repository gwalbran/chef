class ImosArtifactFetcher

  def initialize
    load_dependencies
  end

  def load_dependencies
    require 'json'
    require 'net/http'
  end

  def fetch_artifact(artifact_manifest, node)
    archive_type = artifact_manifest['archiveType'] || node[:imos_artifacts][:archive_type]
    if archive_type == 'jenkins'
      return cache_jenkins_artifact(artifact_manifest, node)
    elsif archive_type == 'archiva'
      return cache_archiva_artifact(artifact_manifest)
    elsif archive_type == 'local'
      return cache_local_artifact(artifact_manifest)
    else
      Chef::Log.error("Unknown archive type #{archive_type}")
    end
  end

  def cache_jenkins_artifact(artifact_manifest, node)

    # Check if there is a use from local cache override and if we know the name of the
    # file so we don't have to query jerkins at all
    if node[:imos_artifacts][:from_local_cache] && artifact_manifest['filename']
      # Return the locally cached file
      Chef::Log.info("Returning locally cached file at #{Chef::Config[:file_cache_path]}/#{artifact_manifest['filename']} due to node configuration")
      return "#{Chef::Config[:file_cache_path]}/#{artifact_manifest['filename']}", false
    end

    # Get the jenkins api creds
    uri_base = artifact_manifest['ci_url'] || node[:imos_artifacts][:ci_url]
    uri = URI.escape("#{uri_base}/job/#{artifact_manifest['job']}/lastSuccessfulBuild");
    jenkins = JenkinsArtifact.new(uri, nil, nil)

    begin
      jenkins_creds = Chef::EncryptedDataBagItem.load("passwords", "jenkins-api")
      jenkins = JenkinsArtifact.new(
        uri,
        jenkins_creds['username'],
        jenkins_creds['password']
      )
    rescue
      Chef::Log.warn("Not using authentication for jenkins download from '#{uri}'")
    end

    return jenkins.cache(artifact_manifest, Chef::Config[:file_cache_path])
  end

  def cache_archiva_artifact(artifact_manifest)
    extension = artifact_manifest['extension'] || '.war'
    filename = "#{Chef::Config[:file_cache_path]}/#{artifact_manifest['id']}" + extension
    if filename && !::File.exists?(filename)
      filename = download(artifact_manifest['url'], artifact_manifest['username'], artifact_manifest['password'], filename)
    end

    return filename
  end

  def cache_local_artifact(artifact_manifest)
    extension = artifact_manifest['extension'] || '.war'
    dst_filename = "#{Chef::Config[:file_cache_path]}/#{artifact_manifest['id']}" + extension
    src_filename = artifact_manifest['url']

    if !File.exists?(src_filename)
      Chef::Application.fatal!("Source file does not exist: #{src_filename}")
    end

    if dst_filename && !file_exists_unchanged(src_filename, dst_filename)
      Chef::Log.debug("Copying '#{src_filename}' to '#{dst_filename}'...")
      FileUtils.copy(src_filename, dst_filename)
    end

    return dst_filename
  end

  def file_exists_unchanged(src_filename, dst_filename)
    return File.exists?(dst_filename) && FileUtils.compare_file(src_filename, dst_filename)
  end

  def download(url, username, password, filename)
    downloaded = true
    f = open(filename, 'w')
    begin
      Chef::Log.info("Fetching #{url}")
      uri = URI(url)

      request = Net::HTTP::Get.new(uri.request_uri)
      request.basic_auth username, password

      response = Net::HTTP.start(uri.host, uri.port) { |http|
        http.request(request)
      }
      f.write(response.body)
      Chef::Log.info("Cached #{url} at #{filename}")
    rescue
      downloaded = false
    ensure
      f.close()
    end

    unless downloaded
      File.delete(filename)
      filename = nil
    end

    filename
  end

end
