#
# Cookbook Name:: imos_artifacts
# Library:: Fetcher
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Logic for fetching artifacts via open-uri
#

require 'open-uri'

module ImosArtifacts
  class Fetcher

    def fetch_artifact(artifact_manifest, node)
      if artifact_manifest['uri']
        return fetch_uri_artifact(artifact_manifest)
      else
        return fetch_jenkins_artifact(artifact_manifest, node)
      end
    end

    def fetch_jenkins_artifact(artifact_manifest, node)
      download_prefix = ::File.join(Chef::Config[:file_cache_path], artifact_manifest['job'])
      jenkins = FetcherJenkins.new(artifact_manifest, node)
      return jenkins.cache(artifact_manifest, download_prefix)
    end

    def fetch_uri_artifact(artifact_manifest)
      uri = artifact_manifest['uri']
      filename = "#{Chef::Config[:file_cache_path]}/#{::File.basename(uri)}"
      username = artifact_manifest['username']
      password = artifact_manifest['password']
      return Fetcher.download_file(uri, filename, username, password)
    end

    def self.download_file(uri, filename, username = nil, password = nil)
      File.open(filename, "wb") do |output|
        begin
          IO.copy_stream(Fetcher.get_uri_retry(uri, username, password), output)
        rescue
          Chef::Application.fatal!("Error downloading file from '#{uri}'")
        end

        Chef::Log.info "Cached '#{uri}' at '#{filename}'"
      end

      return filename
    end

    def self.get_uri(uri, username, password)
      begin
        open_uri_io_object = nil
        if username && password
          Chef::Log.info "Using authentication to download artifact, username: '#{username}'"
          open_uri_io_object = open(uri, "rb", :http_basic_authentication => [ username, password ])
        else
          open_uri_io_object = open(uri, "rb")
        end

        return open_uri_io_object
      rescue
        return nil
      end
    end

    def self.get_uri_retry(uri, username, password, retries = 3)
      for i in 1..retries do
        open_uri_io_object = Fetcher.get_uri(uri, username, password)
        open_uri_io_object and return open_uri_io_object

        Chef::Log.warn "Retrying #{i}/#{retries} '#{uri}'"
        sleep 2
      end
      Chef::Application.fatal! "Could not access '#{uri}'"
    end

  end
end