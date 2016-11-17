#
# authentication
#

deploy_key = Chef::EncryptedDataBagItem.load("deploy_keys", "github")['ssh_priv_key']
git_ssh_wrapper "git" do
  owner        node['imos_jenkins']['user']
  group        node['imos_jenkins']['group']
  ssh_key_data deploy_key
end

jenkins_ssh_dir = File.join(node['jenkins']['master']['home'], ".ssh")

# This is where the ssh wrapper will be
node.set['git_ssh_wrapper'] = File.join("#{jenkins_ssh_dir}", "wrappers", "git_deploy_wrapper.sh")

directory jenkins_ssh_dir do
  user      node['imos_jenkins']['user']
  group     node['imos_jenkins']['group']
  recursive true
end

# Copy the private key
jenkins_ssh_key = Chef::EncryptedDataBagItem.load("users", node['imos_jenkins']['user'])['ssh_priv_key']
file ::File.join(node['jenkins']['master']['home'], '.ssh/id_rsa') do
  content jenkins_ssh_key
  user    node['imos_jenkins']['user']
  group   node['imos_jenkins']['group']
  mode    00400
end

public_key = Chef::Recipe::JenkinsHelper.get_key_pair()[:public_key]

jenkins_user 'chef' do
  full_name 'chef system user'
  public_keys [public_key]
end

admin_users = [ 'chef' ]
search('users', "jenkins_password:*").each do |data_bag|
  admin_users << data_bag['id']
end


# Needed so that ssh logins to various places use the correct key (e.g. github).
# Also, for nectar VMs, we want to accept news hosts automatically.
template ::File.join(node['jenkins']['master']['home'], '.ssh/config') do
  source "ssh_config.erb"
  user   node['imos_jenkins']['user']
  group  node['imos_jenkins']['group']
  mode   00644
  variables({:user => 'jenkins'})
end

# Define all jenkins users
search('users', "jenkins_password:*").each do |data_bag|
  # Until https://github.com/opscode-cookbooks/jenkins/pull/233 is merged, use
  # this mechanism to define users with hashed passwords
  imos_jenkins_user_jbcrypt data_bag['id'] do
    id          data_bag['id']
    full_name   data_bag['full_name']
    email       data_bag['email']
    password    data_bag['jenkins_password'] # TODO PLAIN TEXT SUCKS
    public_keys data_bag['ssh_keys']
  end
end
