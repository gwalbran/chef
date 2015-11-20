#
# Cookbook Name:: imos_artifacts
# Library:: RemoteArtifact
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Logic for retrieving metadata about remote artifacts (e.g. on S3)
#

module ImosArtifacts
  class RemoteArtifact
    def self.get_metadata(artifact_manifest, node)
      require 'aws-sdk'

      metadata = nil

      if (artifact_manifest['uri'])
        metadata = self.get_uri_metadata(artifact_manifest, node)
      elsif
        metadata = self.get_s3_metadata(artifact_manifest, node)
      end

      metadata
    end

    def self.get_s3_metadata(artifact_manifest, node)
      s3 = ::Aws::S3::Client.new(
        region:            node['imos_artifacts']['s3']['region'],
        access_key_id:     node['imos_artifacts']['s3']['access_key_id'],
        secret_access_key: node['imos_artifacts']['s3']['secret_access_key']
      )

      artifact = s3.list_objects(
        bucket:   node['imos_artifacts']['s3']['bucket'],
        prefix:   artifact_manifest['id']
      ).contents.select { |a| a['key'].end_with?('.war', '.zip')}.sort { |a, b| a['key'] <=> b['key'] }.last

      Chef::Application.fatal!(
        "No artifact found on S3, bucket: #{node['imos_artifacts']['s3']['bucket']}, prefix: #{artifact_manifest['id']}", 2
      ) unless artifact

      artifact_filename = ::File.basename(artifact['key'])
      download_prefix = ::File.join(Chef::Config[:file_cache_path], artifact_manifest['job'])

      {
        'cache_path' => download_prefix + "_" + artifact_filename,
        'uri'        => "https://s3-#{node[:imos_artifacts][:s3][:region]}.amazonaws.com/#{node['imos_artifacts']['s3']['bucket']}/#{artifact['key']}"
      }
    end

    def self.get_uri_metadata(artifact_manifest, node)
      {
        'cache_path' => "#{Chef::Config[:file_cache_path]}/#{::File.basename(artifact_manifest['uri'])}"
      }
    end
  end
end
