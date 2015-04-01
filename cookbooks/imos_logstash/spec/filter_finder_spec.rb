require_relative 'spec_helper'

describe FilterFinder do

  describe 'get_filter_config' do
    it 'returns nil when nothing found' do
      expect(FilterFinder.get_filter_config("something")).to eq(nil)
    end

    it 'returns config for existing apps with no data bag' do
      expect(FilterFinder.get_filter_config("portal_4_prod")).to eq("portal")
      expect(FilterFinder.get_filter_config("aatams_system_testing")).to eq("aatams")
      expect(FilterFinder.get_filter_config("geoserver_imos_rc")).to eq("geoserver")
    end

    it 'returns filter config from data bag' do
      allow(Chef::DataBagItem).to receive(:load).with('imos_artifacts', 'app_name').and_return({ 'logstash_filter_config' => 'portal' })
      expect(FilterFinder.get_filter_config("app_name")).to eq("portal")
    end
  end

end
