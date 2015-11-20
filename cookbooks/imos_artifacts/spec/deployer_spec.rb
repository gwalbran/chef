require_relative 'spec_helper'
require 'tmpdir'

module ImosArtifacts
  describe Deployer do
    describe 'build artifact manifests' do
      it 'manifest from data bag' do
        job_data_bag = { 'id' => 'job_id', 'uri' => '/some/path/file.war' }
        allow(Deployer).to receive(:databag_exists?).and_return(true)
        allow(Chef::EncryptedDataBagItem).to receive(:load).with("imos_artifacts", "job_data_bag").and_return(job_data_bag)

        manifest = Deployer.get_artifact_manifest("job_data_bag")
        expect(manifest).to eq (job_data_bag)
      end

      it 'manifest from uri' do
        manifest = Deployer.get_artifact_manifest("http://test.com/file.war")
        expect(manifest['id']).to eq ("file.war")
        expect(manifest['uri']).to eq ("http://test.com/file.war")

        manifest = Deployer.get_artifact_manifest("file:///some/path/file.war")
        expect(manifest['id']).to eq ("file.war")
        expect(manifest['uri']).to eq ("file:///some/path/file.war")
      end

      it 'manifest from job' do
        allow(Deployer).to receive(:databag_exists?).and_return(false)
        manifest = Deployer.get_artifact_manifest("some_job")
        expect(manifest['id']).to eq ("some_job")
        expect(manifest['job']).to eq ("some_job")
      end

      it 'manifest from job with filename' do
        allow(Deployer).to receive(:databag_exists?).and_return(false)
        manifest = Deployer.get_artifact_manifest("some_job/file.war")
        expect(manifest['id']).to eq ("some_job/file.war")
        expect(manifest['job']).to eq ("some_job")
        expect(manifest['filename']).to eq ("file.war")
      end

      it 'manifest from job with filename and build number' do
        allow(Deployer).to receive(:databag_exists?).and_return(false)
        manifest = Deployer.get_artifact_manifest("some_job#1/file.war")
        expect(manifest['id']).to eq ("some_job#1/file.war")
        expect(manifest['job']).to eq ("some_job")
        expect(manifest['build_number']).to eq ("1")
        expect(manifest['filename']).to eq ("file.war")
      end
    end

    describe 'need_deploy?' do
      tmp_dir = ""
      dest_file = ""
      cached_file = ""
      install_dir = ""

      before(:each) do
        tmp_dir = Dir.mktmpdir
        install_dir = ::File.join(tmp_dir, "install_dir")
        dest_file = ::File.join(tmp_dir, "dest_file")
        cached_file = ::File.join(tmp_dir, "cached_file")
      end

      after(:each) do
        ::FileUtils.rm_rf(tmp_dir)
      end

      it 'deploys if destination file does not exist' do
        expect(Deployer.need_deploy?(dest_file, cached_file, install_dir)).to eq(true)
      end

      it 'deploys if cached file is different from destination file' do
        open(cached_file, 'w') { |f| f.puts "content" }
        open(dest_file,   'w') { |f| f.puts "different_content" }
        ::FileUtils.mkdir(install_dir)
        ::FileUtils.touch(::File.join(install_dir, "some_file"))

        expect(Deployer.need_deploy?(dest_file, cached_file, install_dir)).to eq(true)
      end

      it 'deploys if installation directory does not exist' do
        open(cached_file, 'w') { |f| f.puts "content" }
        open(dest_file,   'w') { |f| f.puts "content" }

        expect(Deployer.need_deploy?(dest_file, cached_file, install_dir)).to eq(true)
      end

      it 'deploys if installation directory exists but is empty' do
        open(cached_file, 'w') { |f| f.puts "content" }
        open(dest_file,   'w') { |f| f.puts "content" }
        ::FileUtils.mkdir(install_dir)

        expect(Deployer.need_deploy?(dest_file, cached_file, install_dir)).to eq(true)
      end

      it 'does not deploy if everything is in place' do
        open(cached_file, 'w') { |f| f.puts "content" }
        open(dest_file,   'w') { |f| f.puts "content" }
        ::FileUtils.mkdir(install_dir)
        ::FileUtils.touch(::File.join(install_dir, "some_file"))

        expect(Deployer.need_deploy?(dest_file, cached_file, install_dir)).to eq(false)
      end

    end
  end
end
