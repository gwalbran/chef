#
# Cookbook Name:: imos_artifacts
# Provider:: s3
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Provider to fetch remote artifacts (e.g. from S3 or a specific URL).
#

action :cache do

  # TODO: handle URL
  # uri = artifact_manifest['uri']
  # filename = "#{Chef::Config[:file_cache_path]}/#{::File.basename(uri)}"
  # use remote_file

  jenkins_data_bag = Chef::EncryptedDataBagItem.load('users', 'jenkins')

  puts "new_resource.manifest['cache_path']: #{new_resource.manifest['cache_path']}"

  s3_resource = s3_file new_resource.manifest['cache_path'] do
    remote_path           new_resource.manifest['s3_key']
    bucket                node['imos_artifacts']['s3']['bucket']
    aws_access_key_id     jenkins_data_bag['access_key_id']
    aws_secret_access_key jenkins_data_bag['secret_access_key']
  end

  new_resource.updated_by_last_action(s3_resource.updated_by_last_action?)
end
