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

node.set['jenkins']['master']['runit']['sv_timeout'] = 240
node.set['jenkins']['master']['jvm_options'] = node['imos_jenkins']['master']['jvm_options']

include_recipe 'jenkins::master'
include_recipe 'imos_jenkins::keys'

jenkins_home = node['imos_jenkins']['master']['home']
scm_repo = node['imos_jenkins']['scm_repo']
gitignore_path = File.join(jenkins_home, '.gitignore')

ssh_wrapper = File.join("#{jenkins_home}", ".ssh", "wrappers", "git_deploy_wrapper.sh")

cookbook_file gitignore_path do
  source '.gitignore'
  mode '0755'
  owner node['imos_jenkins']['user']
  group node['imos_jenkins']['group']
  notifies :run, "execute[git_ssh]", :immediately
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
  notifies :run, "execute[set_git_username]", :immediately
end

#Set git global config for jenkins scm-sync-configuration plugin
execute 'set_git_username' do
  command "git config user.name #{node['imos_jenkins']['username']}"
  cwd jenkins_home
  user node['imos_jenkins']['user']
  group node['imos_jenkins']['group']
  notifies :run, "execute[set_git_email]", :immediately
end

execute 'set_git_email' do
  command "git config user.email #{node['imos_jenkins']['email']}"
  cwd jenkins_home
  user node['imos_jenkins']['user']
  group node['imos_jenkins']['group']
end