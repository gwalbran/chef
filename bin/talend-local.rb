#!/usr/bin/env ruby

require 'json'

BASE_DIR = "/vagrant"

def install_talend_artifact(talend_data_bag, harvester_artifact)
  data_bag = JSON.parse(File.read(talend_data_bag))

  if data_bag.has_key?('artifact_filename')
    data_bag.delete('artifact_filename')
  end

  new_data_bag = {}
  data_bag.each do |k, v|
    new_data_bag[k] = v
    if data_bag['id']
      new_data_bag['artifact_id'] = File.join(BASE_DIR, harvester_artifact)
    end
  end

  fd = File.open(talend_data_bag, "w")
  fd.write(JSON.pretty_generate(new_data_bag, :indent => "    ") + "\n")
  fd.close
end

def usage
  script_name = File.basename(__FILE__)
  puts "#{script_name} talend_data_bag harvester_artifact.zip"
  puts "Example: #{script_name} data_bags/talend/aatams_sattag_dm.json tmp/aatams_sattag_dm_harvester_0.1.zip"
  exit 255
end

talend_data_bag = ARGV[0]
harvester_artifact = ARGV[1]

if ARGV.length < 2
  usage
end

if ! File.exists?(talend_data_bag) || ! File.exists?(harvester_artifact)
  usage
end

install_talend_artifact(talend_data_bag, harvester_artifact)
