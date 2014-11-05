require 'minitest/autorun'
require_relative '../artifact_version'

class TestArtifactVersion < MiniTest::Unit::TestCase

  def snapshot_war
    ArtifactVersion.new("Portal2-2.0.0-SNAPSHOT-production.war")
  end

  def production_war
    ArtifactVersion.new("Portal2-2.34.1-production.war")
  end

  def renamed_production_war
    ArtifactVersion.new("Portal-2.34.1-production.war")
  end

  def wfs_scanner_war
    ArtifactVersion.new("wfsScanner-1.1.0.war")
  end

  def test_extracts_version_number_from_snapshot_portal
    assert_equal "2.0.0-SNAPSHOT", snapshot_war.version
  end

  def test_extracts_major_version_number_from_snapshot_portal
    assert_equal 2, snapshot_war.major_version
  end

  def test_extracts_minor_version_number_from_snapshot_portal
    assert_equal 0, snapshot_war.minor_version
  end

  def test_extracts_patch_version_number_from_snapshot_portal
    assert_equal 0, snapshot_war.patch_version
  end

  def test_extracts_special_modifier_from_snapshot_portal
    assert_equal "-", snapshot_war.special_modifier
  end

  def test_extracts_special_from_snapshot_portal
    assert_equal "SNAPSHOT", snapshot_war.special
  end

  def test_extracts_version_number_from_production_portal
    assert_equal "2.34.1-production", production_war.version
  end

  def test_extracts_major_version_number_from_production_portal
    v = snapshot_war
    assert_equal 2, production_war.major_version
  end

  def test_extracts_minor_version_number_from_production_portal
    v = snapshot_war
    assert_equal 34, production_war.minor_version
  end

  def test_extracts_patch_version_number_from_production_portal
    v = snapshot_war
    assert_equal 1, production_war.patch_version
  end

  def test_extracts_special_modifier_from_production_portal
    v = snapshot_war
    assert_equal "-", production_war.special_modifier
  end

  def test_extracts_special_from_production_portal
    v = snapshot_war
    assert_equal "production", production_war.special
  end

  def test_handles_missing_patch_version
    v = ArtifactVersion.new("Portal2-2.34-production.war")
    assert_equal -1, v.patch_version
  end

  def test_orders_by_major_version
    a = [ArtifactVersion.new("Portal2-4.34.1-production.war"), ArtifactVersion.new("Portal2-2.34.1-production.war"), ArtifactVersion.new("Portal2-3.34.1-production.war")]
    a.sort!.reverse!
    assert_equal 4, a[0].major_version
  end

  def test_orders_by_minor_version
    a = [ArtifactVersion.new("Portal2-2.34.1-production.war"), ArtifactVersion.new("Portal2-2.32.1-production.war"), ArtifactVersion.new("Portal2-2.33.1-production.war")]
    a.sort!.reverse!
    assert_equal 34, a[0].minor_version
  end

  def test_orders_by_patch_version
    a = [ArtifactVersion.new("Portal2-2.34.0-production.war"), ArtifactVersion.new("Portal2-2.34.2-production.war"), ArtifactVersion.new("Portal2-2.34.1-production.war")]
    a.sort!.reverse!
    assert_equal 2, a[0].patch_version
  end

  def test_orders_by_patch_version_when_patch_version_missing
    a = [ArtifactVersion.new("Portal2-2.34-production.war"), ArtifactVersion.new("Portal2-2.34.2-production.war"), ArtifactVersion.new("Portal2-2.34.1-production.war")]
    a.sort!.reverse!
    assert_equal 2, a[0].patch_version
  end

  def test_compare_less_than_by_patch_version_when_patch_version_missing
    assert ArtifactVersion.new("Portal2-2.34-production.war") < ArtifactVersion.new("Portal2-2.34.1-production.war")
  end

  def test_extracts_version_number_from_wfs_scanner
    assert_equal "1.1.0", wfs_scanner_war.version
  end

  def test_extracts_major_version_number_from_wfs_scanner
    assert_equal 1, wfs_scanner_war.major_version
  end

  def test_extracts_minor_version_number_from_wfs_scanner
    assert_equal 1, wfs_scanner_war.minor_version
  end

  def test_extracts_patch_version_number_from_wfs_scanner
    assert_equal 0, wfs_scanner_war.patch_version
  end

end
