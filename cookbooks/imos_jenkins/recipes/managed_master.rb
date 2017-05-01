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
ssh_wrapper = File.join("#{jenkins_home}", '.ssh', 'wrappers', 'git_deploy_wrapper.sh')

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
   environment ({"GIT_SSH" => "#{ssh_wrapper}"})
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
