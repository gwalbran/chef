require 'rubygems'
require 'chef/log'
require 'chef'
require 'chef/config'

module Imos
  class CleanerHandler < Chef::Handler

    def initialize
    end

    def exception
      cleanup
    end

    def report
      cleanup
    end

    private

    def cleanup
      data_bag_path = Chef::Config[:data_bag_path]

      Chef::Log.info("Cleaning directory '#{data_bag_path}'")
      FileUtils.rm_rf(Chef::Config[:data_bag_path])
    end
  end
end
