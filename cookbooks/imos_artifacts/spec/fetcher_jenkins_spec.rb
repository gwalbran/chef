require_relative 'spec_helper'

module ImosArtifacts
  describe FetcherJenkins do
    before(:each) do
      allow(Chef::Log).to receive(:warn)
      allow(Chef::Log).to receive(:error)
    end

    describe 'initialize' do
      it 'build job url' do
        job_url = FetcherJenkins.get_job_url("https://ci.aodn.org.au", "a_job", 1)
        expect(job_url).to eq("https://ci.aodn.org.au/job/a_job/1")
      end

      it 'build job url build number set to 0 or nil' do
        job_url = FetcherJenkins.get_job_url("https://ci.aodn.org.au", "a_job", 0)
        expect(job_url).to eq("https://ci.aodn.org.au/job/a_job/lastSuccessfulBuild")

        job_url = FetcherJenkins.get_job_url("https://ci.aodn.org.au", "a_job", nil)
        expect(job_url).to eq("https://ci.aodn.org.au/job/a_job/lastSuccessfulBuild")
      end
    end

    describe 'initialize' do
      artifact_manifest = {}
      node = {}

      before do
        artifact_manifest = {
          'id' => 'some_id',
          'job' => 'some_job'
        }

        node = {
          :imos_artifacts => {
            :jenkins_data_bag => 'jenkins-api',
            :ci_url => 'https://ci.aodn.org.au'
          }
        }
      end

      it 'when data bag set' do
        artifact_manifest['jenkins_data_bag'] = "custom_jenkins_data_bag"
        allow(Chef::EncryptedDataBagItem).to receive(:load).with("passwords", "custom_jenkins_data_bag").and_return(
          {
            'url'      => 'url_from_custom_data_bag',
            'username' => 'username_from_custom_data_bag',
            'password' => 'password_from_custom_data_bag'
          }
        )
        jenkins_artifact = FetcherJenkins.new(artifact_manifest, node)
        expect(jenkins_artifact.url).to eq("url_from_custom_data_bag/job/some_job/lastSuccessfulBuild")
        expect(jenkins_artifact.username).to eq("username_from_custom_data_bag")
        expect(jenkins_artifact.password).to eq("password_from_custom_data_bag")
      end

      it 'with build number' do
        artifact_manifest['build_number'] = 3
        jenkins_artifact = FetcherJenkins.new(artifact_manifest, node)
        expect(jenkins_artifact.url).to eq("https://ci.aodn.org.au/job/some_job/3")
      end

      it 'when no data bag set' do
        allow(Chef::EncryptedDataBagItem).to receive(:load).with("passwords", "jenkins-api").and_return(
          {
            'url'      => 'url_from_data_bag',
            'username' => 'username_from_data_bag',
            'password' => 'password_from_data_bag'
          }
        )
        jenkins_artifact = FetcherJenkins.new(artifact_manifest, node)
        expect(jenkins_artifact.url).to eq("url_from_data_bag/job/some_job/lastSuccessfulBuild")
        expect(jenkins_artifact.username).to eq("username_from_data_bag")
        expect(jenkins_artifact.password).to eq("password_from_data_bag")
      end

      it 'when no default credentials available' do
        jenkins_artifact = FetcherJenkins.new(artifact_manifest, node)
        expect(jenkins_artifact.url).to eq("https://ci.aodn.org.au/job/some_job/lastSuccessfulBuild")
        expect(jenkins_artifact.username).to eq(nil)
        expect(jenkins_artifact.password).to eq(nil)
      end
    end

  end
end
