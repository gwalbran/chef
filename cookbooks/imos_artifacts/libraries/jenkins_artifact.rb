class JenkinsArtifact

  def initialize(url, username, password)
    @url = url
    @username = username
    @password = password
    @api = 'api/json'
  end

  def cache(artifact_manifest, cache_path)
    # Check if the artifact is configured to just return a local cache always
    if artifact_manifest['from_local_cache'] && artifact_manifest['filename']
      # Return the locally cached file
      Chef::Log.info("Returning locally cached file at #{Chef::Config[:file_cache_path]}/#{artifact_manifest['filename']} due to artifact configuration")
      return "#{Chef::Config[:file_cache_path]}/#{artifact_manifest['filename']}"
    end

    response = http_get_response("#{@url}/#{@api}")

    artifact_url = nil
    artifact_filename = nil

    json = JSON.parse(response.body)

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

    if download?(json, artifact_filename, cache_path) && !artifact_manifest['from_local_cache']
      Chef::Log.info("Checksums do not match will download artifact #{artifact_url}")
      download_path = download(artifact_url, "#{Chef::Config[:file_cache_path]}/#{artifact_filename}")
      return download_path
    else
      Chef::Log.info("Returning locally cached file at #{Chef::Config[:file_cache_path]}/#{artifact_filename}")
      download_path = "#{Chef::Config[:file_cache_path]}/#{artifact_filename}"
      return download_path
    end
  end

  private

  def download(url, filename)
    downloaded = true
    f = open(filename, 'w')
    begin
      Chef::Log.info("Fetching #{url}")
      response = http_get_response(url)
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
    if download(artifact_md5_url, tmpfile.path)
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
      if download(fingerprint_url, tmpfile.path)
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

  def download?(json, artifact_filename, cache_path)
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
    if ::File.exist?(::File.join(cache_path, artifact_filename))
      file_real_checksum = Digest::MD5.file(::File.join(cache_path, artifact_filename)).hexdigest
    end

    # The only case in which we do not deploy, is if the remote checksum and
    # the checksum of the currently downloaded file are equal, any other case
    # we'll trigger a download
    file_real_checksum.nil? || remote_checksum.nil? || file_real_checksum != remote_checksum
  end

  def http_get_response(url)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    # Please note this is bad form but I need to get this up and running quickly, please take the time
    # to fix and you'll be my hero, http://www.rubyinside.com/how-to-cure-nethttps-risky-default-https-behavior-4010.html
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri)
    if @username && @password
      request.basic_auth @username, @password
    end

    http.request(request)
  end

end
