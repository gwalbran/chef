#
# Cookbook Name:: imos_artifacts
# Library:: Version
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Version comparison logic
#

module ImosArtifacts
  class Version

    include Comparable

    attr_reader :version, :major_version, :minor_version, :patch_version, :special_modifier, :special

    def initialize(name)
      versionify(name)
    end

    def <=>(other)
      maj = @major_version <=> other.major_version
      return maj unless maj == 0

      min = @minor_version <=> other.minor_version
      return min unless min == 0

      patch = @patch_version <=> other.patch_version
      return patch unless patch == 0

      spec = @special <=> other.special
      return spec unless spec == 0

      0
    end

    private

    def versionify(name)
      /((\d+)\.(\d+)((\.(\d+)){0,1})((\+|-)(\w+)){0,1})/ =~ name
      @version = Regexp.last_match(1)
      @major_version = Regexp.last_match(2).to_i
      @minor_version = Regexp.last_match(3).to_i
      @patch_version = safe_patch_version(Regexp.last_match(6))
      @special_modifier = Regexp.last_match(8)
      @special = Regexp.last_match(9)
    end

    def safe_patch_version(match)
      if match.nil? || match == ""
        return -1
      else
        return match.to_i
      end
    end

    def to_s
      "#{@version} [#{@major_version}, #{@minor_version}, #{@patch_version}, #{@special_modifier}#{@special}]"
    end

  end
end
