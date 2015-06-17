require_relative 'spec_helper'

describe FilterFinder do

  describe 'get_filter_config' do
    it 'returns short application name when no data bag' do
      allow(ImosArtifacts::Deployer).to receive(:get_artifact_manifest).and_return(nil)
      expect(FilterFinder.get_filter_config(nil)).to eq(nil)
      expect(FilterFinder.get_filter_config("")).to eq(nil)
      expect(FilterFinder.get_filter_config("portal")).to eq("portal")
      expect(FilterFinder.get_filter_config("GeoNetwork")).to eq("geonetwork")
      expect(FilterFinder.get_filter_config("portal_4_prod")).to eq("portal")
      expect(FilterFinder.get_filter_config("aatams_system_testing")).to eq("aatams")
      expect(FilterFinder.get_filter_config("geoserver_imos_rc")).to eq("geoserver")
    end

    it 'returns filter config from data bag' do
      allow(ImosArtifacts::Deployer).to receive(:get_artifact_manifest).with('app_name').and_return({ 'logstash_filter_config' => 'portal' })
      expect(FilterFinder.get_filter_config("app_name")).to eq("portal")
    end
  end

end
