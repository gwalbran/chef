require_relative 'spec_helper'

describe ArtifactVersion do
  snapshot_war = ArtifactVersion.new("Portal2-2.0.0-SNAPSHOT-production.war")
  production_war = ArtifactVersion.new("Portal2-2.34.1-production.war")
  renamed_production_war = ArtifactVersion.new("Portal-2.34.1-production.war")
  wfs_scanner_war = ArtifactVersion.new("wfsScanner-1.1.0.war")

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
      v = ArtifactVersion.new("Portal2-2.34-production.war")
      expect(-1).to eq(v.patch_version)
    end

    it 'test_orders_by_major_version' do
      a = [ArtifactVersion.new("Portal2-4.34.1-production.war"), ArtifactVersion.new("Portal2-2.34.1-production.war"), ArtifactVersion.new("Portal2-3.34.1-production.war")]
      a.sort!.reverse!
      expect(4).to eq(a[0].major_version)
    end

    it 'test_orders_by_minor_version' do
      a = [ArtifactVersion.new("Portal2-2.34.1-production.war"), ArtifactVersion.new("Portal2-2.32.1-production.war"), ArtifactVersion.new("Portal2-2.33.1-production.war")]
      a.sort!.reverse!
      expect(34).to eq(a[0].minor_version)
    end

    it 'test_orders_by_patch_version' do
      a = [ArtifactVersion.new("Portal2-2.34.0-production.war"), ArtifactVersion.new("Portal2-2.34.2-production.war"), ArtifactVersion.new("Portal2-2.34.1-production.war")]
      a.sort!.reverse!
      expect(2).to eq(a[0].patch_version)
    end

    it 'test_orders_by_patch_version_when_patch_version_missing' do
      a = [ArtifactVersion.new("Portal2-2.34-production.war"), ArtifactVersion.new("Portal2-2.34.2-production.war"), ArtifactVersion.new("Portal2-2.34.1-production.war")]
      a.sort!.reverse!
      expect(2).to eq(a[0].patch_version)
    end

    it 'test_compare_less_than_by_patch_version_when_patch_version_missing' do
      expect(ArtifactVersion.new("Portal2-2.34-production.war")).to be < ArtifactVersion.new("Portal2-2.34.1-production.war")
    end

    it 'test_extracts_version_number_from_wfs_scanner' do
      expect("1.1.0").to eq(wfs_scanner_war.version)
    end

    it 'test_extracts_major_version_number_from_wfs_scanner' do
      expect(1).to eq(wfs_scanner_war.major_version)
    end

    it 'test_extracts_minor_version_number_from_wfs_scanner' do
      expect(1).to eq(wfs_scanner_war.minor_version)
    end

    it 'test_extracts_patch_version_number_from_wfs_scanner' do
      expect(0).to eq(wfs_scanner_war.patch_version)
    end

  end
end