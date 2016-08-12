require_relative 'spec_helper'

module ImosArtifacts
  describe Version do
    snapshot_war = Version.new("Portal2-2.0.0-SNAPSHOT-production.war")
    production_war = Version.new("Portal2-2.34.1-production.war")
    renamed_production_war = Version.new("Portal-2.34.1-production.war")

    describe 'version compare' do
      it 'test_extracts_version_number_from_snapshot_portal' do
        expect("2.0.0-SNAPSHOT").to eq(snapshot_war.version)
      end

      it 'test_extracts_major_version_number_from_snapshot_portal' do
        expect(2).to eq( snapshot_war.major_version)
      end

      it 'test_extracts_minor_version_number_from_snapshot_portal' do
        expect(0).to eq(snapshot_war.minor_version)
      end

      it 'test_extracts_patch_version_number_from_snapshot_portal' do
        expect(0).to eq(snapshot_war.patch_version)
      end

      it 'test_extracts_special_modifier_from_snapshot_portal' do
        expect("-").to eq(snapshot_war.special_modifier)
      end

      it 'test_extracts_special_from_snapshot_portal' do
        expect("SNAPSHOT").to eq(snapshot_war.special)
      end

      it 'test_extracts_version_number_from_production_portal' do
        expect("2.34.1-production").to eq(production_war.version)
      end

      it 'test_extracts_major_version_number_from_production_portal' do
        expect(2).to eq(production_war.major_version)
      end

      it 'test_extracts_minor_version_number_from_production_portal' do
        expect(34).to eq(production_war.minor_version)
      end

      it 'test_extracts_patch_version_number_from_production_portal' do
        expect(1).to eq(production_war.patch_version)
      end

      it 'test_extracts_special_modifier_from_production_portal' do
        expect("-").to eq(production_war.special_modifier)
      end

      it 'test_extracts_special_from_production_portal' do
        expect("production").to eq(production_war.special)
      end

      it 'test_handles_missing_patch_version' do
        v = Version.new("Portal2-2.34-production.war")
        expect(-1).to eq(v.patch_version)
      end

      it 'test_orders_by_major_version' do
        a = [Version.new("Portal2-4.34.1-production.war"), Version.new("Portal2-2.34.1-production.war"), Version.new("Portal2-3.34.1-production.war")]
        a.sort!.reverse!
        expect(4).to eq(a[0].major_version)
      end

      it 'test_orders_by_minor_version' do
        a = [Version.new("Portal2-2.34.1-production.war"), Version.new("Portal2-2.32.1-production.war"), Version.new("Portal2-2.33.1-production.war")]
        a.sort!.reverse!
        expect(34).to eq(a[0].minor_version)
      end

      it 'test_orders_by_patch_version' do
        a = [Version.new("Portal2-2.34.0-production.war"), Version.new("Portal2-2.34.2-production.war"), Version.new("Portal2-2.34.1-production.war")]
        a.sort!.reverse!
        expect(2).to eq(a[0].patch_version)
      end

      it 'test_orders_by_patch_version_when_patch_version_missing' do
        a = [Version.new("Portal2-2.34-production.war"), Version.new("Portal2-2.34.2-production.war"), Version.new("Portal2-2.34.1-production.war")]
        a.sort!.reverse!
        expect(2).to eq(a[0].patch_version)
      end

      it 'test_compare_less_than_by_patch_version_when_patch_version_missing' do
        expect(Version.new("Portal2-2.34-production.war")).to be < Version.new("Portal2-2.34.1-production.war")
      end

      it 'test_compare_version_special_absent' do
        expect(Version.new("geoserver-1.0.1.war")).to be < Version.new("geoserver-1.0.1-imos.war")
      end

    end
  end
end
