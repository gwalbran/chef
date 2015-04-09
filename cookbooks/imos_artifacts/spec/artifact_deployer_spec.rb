require_relative 'spec_helper'
require 'tmpdir'

describe ArtifactDeployer do

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
      expect(ArtifactDeployer.need_deploy?(dest_file, cached_file, install_dir)).to eq(true)
    end

    it 'deploys if cached file is different from destination file' do
      open(cached_file, 'w') { |f| f.puts "content" }
      open(dest_file,   'w') { |f| f.puts "different_content" }
      ::FileUtils.mkdir(install_dir)
      ::FileUtils.touch(::File.join(install_dir, "some_file"))

      expect(ArtifactDeployer.need_deploy?(dest_file, cached_file, install_dir)).to eq(true)
    end

    it 'deploys if installation directory does not exist' do
      open(cached_file, 'w') { |f| f.puts "content" }
      open(dest_file,   'w') { |f| f.puts "content" }

      expect(ArtifactDeployer.need_deploy?(dest_file, cached_file, install_dir)).to eq(true)
    end

    it 'deploys if installation directory exists but is empty' do
      open(cached_file, 'w') { |f| f.puts "content" }
      open(dest_file,   'w') { |f| f.puts "content" }
      ::FileUtils.mkdir(install_dir)

      expect(ArtifactDeployer.need_deploy?(dest_file, cached_file, install_dir)).to eq(true)
    end

    it 'does not deploy if everything is in place' do
      open(cached_file, 'w') { |f| f.puts "content" }
      open(dest_file,   'w') { |f| f.puts "content" }
      ::FileUtils.mkdir(install_dir)
      ::FileUtils.touch(::File.join(install_dir, "some_file"))

      expect(ArtifactDeployer.need_deploy?(dest_file, cached_file, install_dir)).to eq(false)
    end

  end
end
