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

  if (new_resource.manifest['uri'])
    remote_file_resource = remote_file new_resource.manifest['cache_path'] do
      source  new_resource.manifest['uri']
      retries node[:imos_artifacts][:download_retries]
    end

    new_resource.updated_by_last_action(remote_file_resource.updated_by_last_action?)
  elsif
    jenkins_data_bag = Chef::EncryptedDataBagItem.load('users', 'jenkins')

    s3_resource = s3_file new_resource.manifest['cache_path'] do
      remote_path           new_resource.manifest['s3_key']
      bucket                node['imos_artifacts']['s3']['bucket']
      aws_access_key_id     jenkins_data_bag['access_key_id']
      aws_secret_access_key jenkins_data_bag['secret_access_key']
      retries               node[:imos_artifacts][:download_retries]
    end

    new_resource.updated_by_last_action(s3_resource.updated_by_last_action?)
  end
end
