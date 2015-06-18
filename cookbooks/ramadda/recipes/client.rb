#
# Cookbook Name:: ramadda
# Recipe:: client
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

include_recipe "imos_artifacts"

ramadda_client_cache_dir = Chef::Config[:file_cache_path]
ramadda_client_cache_path = "#{ramadda_client_cache_dir}/ramaddaclient.zip"

# Fetch the client
ruby_block "fetch_ramadda_client" do
  block do
    # The imos artifact fetcher depends on these libs but can't be parsed until they are installed
    require 'rubygems'
    require 'json'
    require 'net/http'

    artifact_manifest = Chef::EncryptedDataBagItem.load("imos_artifacts", "ramadda-client")
    fetcher = ImosArtifacts::Fetcher.new
    cache_zip_path, artifact_downloaded = fetcher.fetch_artifact(artifact_manifest, node)

    # At this point in time this actually copies the file over the top of itself
    # because the artifact fetcher downloads the file to Chef::Config[:file_cache_path] but
    # we don't want this recipe to make that assumption because if the artifact fetcher
    # changes then this breaks
    if !::File.exists?(ramadda_client_cache_path) || ::File.mtime(ramadda_client_cache_path) < ::File.mtime(cache_zip_path)
      FileUtils.cp cache_zip_path, ramadda_client_cache_path
    end
  end
end

package "unzip"

execute "unpack #{ramadda_client_cache_path}" do
  command "unzip -uo -d /usr/local #{ramadda_client_cache_path}"
  action :run
end

# Chmod the sh script
ramadda_client_script = "/usr/local/ramaddaclient/ramaddaclient.sh"
file ramadda_client_script do
  owner "root"
  group "root"
  mode "0755"
end
