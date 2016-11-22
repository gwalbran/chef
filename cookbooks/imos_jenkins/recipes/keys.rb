Chef::Recipe::JenkinsHelper.authenticate node

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
  mode    00600
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

# Add the github.com key to known_hosts
execute "add-github-ssh-key" do
  command "su - #{node['imos_jenkins']['user']} -c 'ssh github.com -o StrictHostKeyChecking=no; true'"
  action  :run
  not_if  "su - #{node['imos_jenkins']['user']} -c 'test -f .ssh/known_hosts'"
end
