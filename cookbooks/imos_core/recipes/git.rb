#
# Cookbook Name:: imos_core
# Recipe:: git
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#

node['imos_core']['git']['repositories'].each do |repo|
  git repo['dst'] do
    repository repo['src']
    revision   repo['revision'] || "master"
    depth      1
    action     :sync
    user       repo['user']  || "root"
    group      repo['group'] || "root"
  end
end
