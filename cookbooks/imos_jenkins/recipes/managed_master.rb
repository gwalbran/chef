#
# Cookbook Name:: jenkins
# Recipe:: managed_master
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Recipe to configure a fully-chef managed jenkins master node.

include_recipe 'imos_java'
include_recipe 'imos_jenkins::node_common'

node.set['jenkins']['master']['runit']['sv_timeout'] = 240
node.set['jenkins']['master']['jvm_options'] = node['imos_jenkins']['master']['jvm_options']

include_recipe 'jenkins::master'
include_recipe 'imos_jenkins::keys'

# Give jenkins permission to run sudo commands - TODO: remove the need for sudo in jobs
sudo 'jenkins' do
  group 'jenkins'
  runas    'ALL'
  commands ['ALL']
  host     'ALL'
  nopasswd true
end

jenkins_home = node['imos_jenkins']['master']['home']
scm_repo = node['imos_jenkins']['scm_repo']

ssh_wrapper = File.join("#{jenkins_home}", '.ssh', 'wrappers', 'git_deploy_wrapper.sh')

node['imos_jenkins']['plugins'].each do |plugin_id|
  jenkins_plugin plugin_id do
    notifies :restart, 'service[jenkins]', :immediately
  end
end

execute 'git_ssh' do
  command "GIT_SSH=#{ssh_wrapper}"
  user node['imos_jenkins']['user']
  group node['imos_jenkins']['group']
  notifies :run, "execute[init_jenkins_scm]", :immediately
end

# Overwrite local files with those present in SCM
execute 'init_jenkins_scm' do
  command "git rev-parse --is-inside-work-tree || { git init && git remote add origin #{scm_repo} && git fetch && git reset --hard origin/master; }"
  cwd jenkins_home
  user node['imos_jenkins']['user']
  group node['imos_jenkins']['group']
end
