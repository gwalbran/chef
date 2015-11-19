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

      if (artifact_manifest['uri'])
        self.get_uri_metadata(artifact_manifest, node)
      elsif
        self.get_s3_metadata(artifact_manifest, node)
      end

    end

    def self.get_s3_metadata(artifact_manifest, node)
      jenkins_data_bag = Chef::EncryptedDataBagItem.load('users', 'jenkins')

      s3 = ::Aws::S3::Client.new(
        region:            node['imos_artifacts']['s3']['region'],
        access_key_id:     jenkins_data_bag['access_key_id'],
        secret_access_key: jenkins_data_bag['secret_access_key']
      )

      # TODO: get latest
      artifact = s3.list_objects(
        bucket:   node['imos_artifacts']['s3']['bucket'],
        prefix:   artifact_manifest['id'],
        max_keys: 1
      ).contents[0]

      Chef::Application.fatal!(
        "No artifact found on S3, bucket: #{node['imos_artifacts']['s3']['bucket']}, prefix: #{artifact_manifest['id']}", 2
      ) unless artifact

      artifact_filename = ::File.basename(artifact['key'])
      download_prefix = ::File.join(Chef::Config[:file_cache_path], artifact_manifest['job'])

      {
        'cache_path' => download_prefix + "_" + artifact_filename,
        's3_key'     => artifact['key']
      }
    end

    def self.get_uri_metadata(artifact_manifest, node)
      {
        'cache_path' => "#{Chef::Config[:file_cache_path]}/#{::File.basename(artifact_manifest['uri'])}"
      }
    end
  end
end
