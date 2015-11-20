require_relative 'spec_helper'

module ImosArtifacts
  describe RemoteArtifact do

    artifact_manifest = nil
    node = nil

    before do
      artifact_manifest = {}
      node  = {}
    end

    describe 's3 or uri' do

      before do
        allow(ImosArtifacts::RemoteArtifact).to receive(:get_s3_metadata)
        allow(ImosArtifacts::RemoteArtifact).to receive(:get_uri_metadata)
      end

      it 's3' do
        ImosArtifacts::RemoteArtifact.get_metadata(artifact_manifest, node)
        expect(ImosArtifacts::RemoteArtifact).to have_received(:get_s3_metadata)
      end

      it 'uri' do
        artifact_manifest['uri'] = 'http://example.com'
        ImosArtifacts::RemoteArtifact.get_metadata(artifact_manifest, node)
        expect(ImosArtifacts::RemoteArtifact).to have_received(:get_uri_metadata)
      end
    end


    it 's3 metadata' do
      artifact_manifest['job'] = 'awesome_job'

      node[:imos_artifacts] = {
        :s3 => {
          :region => 'region',
          :bucket => 'bucket'
        }
      }
      Chef::Config[:file_cache_path] = '/tmp/cache'

      allow(ImosArtifacts::RemoteArtifact).to receive(:get_highest_version_from_s3) {
        { 'key' => 'the_key.war' }
      }

      metadata = ImosArtifacts::RemoteArtifact.get_s3_metadata(artifact_manifest, node)

      expect(metadata['cache_path']).to eq('/tmp/cache/awesome_job_the_key.war')
      expect(metadata['uri']).to eq('https://s3-region.amazonaws.com/bucket/the_key.war')
    end

  end
end
