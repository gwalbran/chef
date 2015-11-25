#
# Cookbook Name:: imos_po
# Library:: watch_jobs
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#

class Chef::Recipe::WatchJobs

  # Returns watches as an array, easily parse-able by a template
  def self.get_watches(watch_dir)
    watchlists = {}
    if File.exists?(watch_dir)
      Dir.foreach(watch_dir) do |file|
        if file.end_with?(".json")
          file_full_path = ::File.join(watch_dir, file)
          watch_config = JSON.parse(File.read(file_full_path))
          watch_id = file.gsub(/\.json$/, "")
          watchlists[watch_id] = watch_config
        end
      end
    end

    return watchlists
  end

end
