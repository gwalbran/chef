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
    def self.get_metadata(artifact_id, node)

      require 'aws-sdk'

      artifact_manifest = ImosArtifacts::Deployer.get_artifact_manifest(artifact_id)

      # TODO
      # uri = artifact_manifest['uri']
      # filename = "#{Chef::Config[:file_cache_path]}/#{::File.basename(uri)}"
      # use remote_file

      jenkins_data_bag = Chef::EncryptedDataBagItem.load('users', 'jenkins')

      s3 = ::Aws::S3::Client.new(
        region:            node['imos_artifacts']['s3']['region'],
        access_key_id:     jenkins_data_bag['access_key_id'],
        secret_access_key: jenkins_data_bag['secret_access_key']
      )

      artifact = s3.list_objects(
        bucket:   node['imos_artifacts']['s3']['bucket'],
        prefix:   artifact_id,
        max_keys: 1
      ).contents[0]

      artifact_filename = ::File.basename(artifact['key'])
      download_prefix = ::File.join(Chef::Config[:file_cache_path], artifact_manifest['job'])

      {
        'cache_path' => download_prefix + "_" + artifact_filename,
        's3_key'     => artifact['key']
      }
    end
  end
end
