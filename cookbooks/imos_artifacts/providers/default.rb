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
  remote_file_resource = remote_file new_resource.manifest['cache_path'] do
    source  new_resource.manifest['uri']
    retries node[:imos_artifacts][:download_retries]
  end

  new_resource.updated_by_last_action(remote_file_resource.updated_by_last_action?)
end
