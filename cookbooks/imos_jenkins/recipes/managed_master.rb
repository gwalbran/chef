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

jenkins_home = node['imos_jenkins']['master']['home']
scm_repo = node['imos_jenkins']['scm_repo']

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

sdkman_script_path = File.join(Chef::Config[:file_cache_path], 'sdkman_installer.sh')

remote_file sdkman_script_path do
  source node['imos_jenkins']['sdkman_install_url']
  user node['imos_jenkins']['user']
  group node['imos_jenkins']['group']
  mode 0700
  notifies :run, 'bash[install_sdkman]', :immediately
end

bash 'install_sdkman' do
  code <<-EOH
   sh #{sdkman_script_path}
  EOH
  user node['imos_jenkins']['user']
  environment ({ 'HOME' => ::Dir.home(node['imos_jenkins']['user']), 'USER' => node['imos_jenkins']['user']})
  action :nothing
  not_if { ::File.exist?(::File.join(jenkins_home, '.sdkman', 'bin', 'sdkman-init.sh'))}
end

node['imos_jenkins']['managed_master']['grails_installations'].each do |grails_version|
  bash 'install_grails' do
    code <<-EOH
    source "#{jenkins_home}/.sdkman/bin/sdkman-init.sh"
    sdk install grails #{grails_version}
    EOH
    user node['imos_jenkins']['user']
    action :nothing
    environment ({ 'HOME' => ::Dir.home(node['imos_jenkins']['user']), 'USER' => node['imos_jenkins']['user']})
    subscribes :run, 'bash[install_sdkman]', :delayed
  end
end

require 'openssl'
require 'net/ssh'

if !Chef::Config['dev']
  jenkins_ssh_key = Chef::EncryptedDataBagItem.load("users", "chef")['ssh_private_key']
  key = OpenSSL::PKey::RSA.new(jenkins_ssh_key)
  private_key = key.to_pem

  node.run_state[:jenkins_private_key] = private_key
end

node['imos_jenkins']['plugins'].each do |plugin_id, version|
  jenkins_plugin plugin_id do
    version version
    notifies :restart, 'service[jenkins]', :immediately
  end
end

# Overwrite local files with those present in SCM
 execute 'init_jenkins_scm' do
   command "git rev-parse --is-inside-work-tree || { git init && git remote add origin #{scm_repo} && git fetch && git reset --hard origin/master; }"
   cwd jenkins_home
   user node['imos_jenkins']['user']
   group node['imos_jenkins']['group']
   environment ({"GIT_SSH" => File.join(jenkins_home, '.ssh', 'wrappers', 'git_deploy_wrapper.sh')})
 end

git_config_email = node['imos_jenkins']['scm_email']
git_config_user = node['imos_jenkins']['scm_user']

execute 'init_git_global_conf' do
  command %{git config --global user.email "#{git_config_email}" ; git config --global user.name "#{git_config_user}"}
  cwd jenkins_home
  user node['imos_jenkins']['user']
  group node['imos_jenkins']['group']
  environment ({"HOME" => jenkins_home})
end

# AWS passwords
envvars = {}

if Chef::Config['dev']
  credentials_databag_name = node['imos_jenkins']['s3']['credentials_databag_dev']
else
  credentials_databag_name = node['imos_jenkins']['s3']['credentials_databag']
end

credentials_databag = Chef::EncryptedDataBagItem.load("passwords", credentials_databag_name)

envvars[:AWS_ACCESS_KEY] = credentials_databag['access_key_id']
envvars[:AWS_SECRET_KEY] = credentials_databag['secret_access_key']
envvars[:S3_ARTIFACT_BUCKET] = credentials_databag['artifact_bucket']

template "#{jenkins_home}/env.properties" do
  source   "env.properties.erb"
  user node['imos_jenkins']['user']
  group node['imos_jenkins']['group']
  mode    00644
  owner    node['imos_jenkins']['user']
  variables ({
      :vars => envvars
  })
end
