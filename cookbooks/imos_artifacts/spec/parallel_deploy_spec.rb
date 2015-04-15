require_relative 'spec_helper'
require 'tempfile'

describe ParallelDeploy do

  describe 'add_version' do
    it 'empty or nil version' do
      result = ParallelDeploy.add_version("/tomcat/webapps/imos.war", "")
      expect("/tomcat/webapps/imos.war").to eq(result)

      result = ParallelDeploy.add_version("/tomcat/webapps/imos.war", nil)
      expect("/tomcat/webapps/imos.war").to eq(result)
    end

    it '.war file' do
      result = ParallelDeploy.add_version("/tomcat/webapps/imos.war", "1429007040")
      expect("/tomcat/webapps/imos##1429007040.war").to eq(result)
    end

    it 'directory' do
      result = ParallelDeploy.add_version("/tomcat/webapps/imos", "1429007040")
      expect("/tomcat/webapps/imos##1429007040").to eq(result)
    end
  end

  describe 'tomcat_version_for_artifact' do
    it 'file exists' do
    end

    it 'file erro' do
      expect("").to eq(ParallelDeploy.tomcat_version_for_artifact("/NON-EXISTING-FILE"))
    end

    it 'file exists' do
      mocked_stat_struct = OpenStruct.new
      mocked_stat_struct.mtime = 123
      allow(File).to receive(:stat).with("file").and_return(mocked_stat_struct)

      expect("123").to eq(ParallelDeploy.tomcat_version_for_artifact("file"))
    end
  end

end
