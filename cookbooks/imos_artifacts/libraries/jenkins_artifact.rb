require 'json'

class JenkinsArtifact
  attr_reader :url
  attr_reader :username
  attr_reader :password

  def initialize(artifact_manifest, node)
    job_name = artifact_manifest['job']

    if artifact_manifest['jenkins_data_bag']
      jenkins_creds = Chef::EncryptedDataBagItem.load("passwords", artifact_manifest['jenkins_data_bag'])
      @url = JenkinsArtifact::get_job_url(jenkins_creds['url'], job_name)
      @username = jenkins_creds['username']
      @password = jenkins_creds['password']
    else
      begin
        jenkins_creds = Chef::EncryptedDataBagItem.load("passwords", node[:imos_artifacts][:jenkins_data_bag])
        @url = JenkinsArtifact::get_job_url(jenkins_creds['url'], job_name)
        @username = jenkins_creds['username']
        @password = jenkins_creds['password']
      rescue
        @url = JenkinsArtifact::get_job_url(node[:imos_artifacts][:ci_url], job_name)
        Chef::Log.warn("Not using authentication for jenkins download from '#{@url}'")
      end
    end

    @api = 'api/json'
  end

  def self.get_job_url(url_base, job_name)
    return URI.escape("#{url_base}/job/#{job_name}/lastSuccessfulBuild")
  end

  def cache(artifact_manifest, download_prefix)
    artifact_url = nil
    artifact_filename = nil

    json = JSON.parse(ImosArtifactFetcher.get_uri_content_retry("#{@url}/#{@api}", @username, @password))

    # Abort run if there are no archived artifacts on jenkins
    Chef::Application.fatal!("Jenkins build contains no archived artifacts!", 1) if json['artifacts'].empty?

    if artifact_manifest['filename']
      json['artifacts'].each do |artifact|

        if artifact['fileName'] == artifact_manifest['filename']
          # This is the artifact we eventually want to do something with
          artifact_filename = artifact['fileName']
          artifact_url = "#{@url}/artifact/#{artifact['relativePath']}"
          break
        end
      end
    else
      # This is the scenario that plays out for production portal releases, essentially there is an
      # assumption that all artifacts are in SemVer and this code simply fetches the one with the
      # highest version number
      current_version = nil
      json['artifacts'].each do |artifact|
        if current_version.nil? || current_version < version(artifact['fileName'])
          current_version = version(artifact['fileName'])
          artifact_filename = artifact['fileName']
          artifact_url = "#{@url}/artifact/#{artifact['relativePath']}"
        end
      end
    end

    Chef::Log.info("Downloading artifact version '#{current_version}'")

    download_path = download_prefix + "_" + artifact_filename

    if need_download?(json, artifact_filename, download_path)
      Chef::Log.info("Checksums do not match will download artifact #{artifact_url}")
      ImosArtifactFetcher.download_file(artifact_url, download_path, @username, @password)
      return download_path
    else
      Chef::Log.info("Returning locally cached file at '#{download_path}'")
      return download_path
    end
  end

  private

  def checksum_from_file(file)
    checksum = ''
    if File.exists?(file)
      checksum = checksum_from_entry(IO.readlines(file)[0])
    end
    checksum
  end

  def checksum_from_entry(entry)
    checksum = ''
    if entry && entry.split(' ')
      checksum = entry.split('  ')[0]
    end
    checksum
  end

  def version(filename)
    ArtifactVersion.new(filename)
  end

  def get_artifact_md5_from_md5_file(artifact_md5_url)
    tmpfile = Tempfile.new('jenkins-artifact-md5')
    if ImosArtifactFetcher.download_file(artifact_md5_url, tmpfile.path, @username, @password)
      remote_checksum = checksum_from_file(tmpfile.path)
    else
      Chef::Log.warn("Could not obtain md5 via md5 file at '#{artifact_md5_url}'")
    end
    tmpfile.unlink

    return remote_checksum
  end

  def get_artifact_md5_via_fingerprint(artifact_url)
    # nokogiri should be installed via the imos_artifacts::default recipe
    require 'nokogiri'
    require 'tempfile'

    artifact_md5_checksum = nil

    tmpfile = Tempfile.new('jenkins-fingerprint')
    begin
      fingerprint_url = "#{artifact_url}/*fingerprint*/"
      if ImosArtifactFetcher.download_file(fingerprint_url, tmpfile.path, @username, @password)
        html_page = Nokogiri::HTML(open(tmpfile.path))
        # Expect something like 'MD5: 00000000000000000000000000000000', so strip
        # the first 4 chars
        artifact_md5_checksum = html_page.css('div.md5sum')[0].text[5..-1]
      end
    rescue
      Chef::Log.warn("Could not obtain md5 via jenkins fingerprint for artifact '#{artifact_url}'")
    end
    tmpfile.unlink

    return artifact_md5_checksum
  end

  def need_download?(json, artifact_filename, download_path)
    remote_checksum = nil

    # Try obtaining md5 checksum from .md5 file in jenkins
    json['artifacts'].each do |artifact|
      checksum_filename = "#{artifact_filename}.md5"
      next unless artifact['fileName'] == checksum_filename
      remote_checksum = get_artifact_md5_from_md5_file("#{@url}/artifact/#{artifact['relativePath']}")
    end

    # Try obtaining md5 checksum from fingerprint on jenkins job
    if remote_checksum.nil?
      json['artifacts'].each do |artifact|
        next unless artifact['fileName'] == artifact_filename
        remote_checksum = get_artifact_md5_via_fingerprint("#{@url}/artifact/#{artifact['relativePath']}")
      end
    end

    # Checksum of file already downloaded
    file_real_checksum = nil
    if ::File.exist?(download_path)
      file_real_checksum = Digest::MD5.file(download_path).hexdigest
    end

    # The only case in which we do not deploy, is if the remote checksum and
    # the checksum of the currently downloaded file are equal, any other case
    # we'll trigger a download
    file_real_checksum.nil? || remote_checksum.nil? || file_real_checksum != remote_checksum
  end

end
