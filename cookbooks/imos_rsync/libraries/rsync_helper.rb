#
# Cookbook Name:: imos_rsync
# Library:: rsync_helper
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#

class Chef::Recipe::RsyncHelper
  # Appends prefix if directory path is relative
  def self.amend_path(dir, prefix)
    if dir.start_with?("/")
      return dir
    else
      return ::File.join(prefix, dir)
    end
  end
end
