#
# authentication
#
ssh_private_key = Chef::EncryptedDataBagItem.load("users", "chef")['ssh_private_key']

require 'openssl'
require 'net/ssh'

key = OpenSSL::PKey::RSA.new(ssh_private_key)
private_key = key.to_pem
public_key = "#{key.ssh_type} #{[key.to_blob].pack('m0')}"

# Set the private key on the Jenkins executor
ruby_block 'set private key' do
  block do
    node.run_state[:jenkins_private_key] = private_key
  end
end

# Create the 'chef' user with the public key
jenkins_user 'chef' do
  full_name 'chef system user'
  public_keys [public_key]
end

# TODO the first time this runs it fails, because there's no authentication
# configured however it still tries to run it using the configured SSH key, and
# this fails. Consecutive runs will succeed if this snippet managed to run (or
# was ran manually
# Turn on basic authentication
jenkins_script 'setup authentication' do
  command <<-EOH.gsub(/^ {4}/, '')
    import jenkins.model.*
    def instance = Jenkins.getInstance()
    import hudson.security.*
    def realm = new HudsonPrivateSecurityRealm(false)
    instance.setSecurityRealm(realm)
    def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
    instance.setAuthorizationStrategy(strategy)
    instance.save()
  EOH
end

# Define all jenkins users
search('users', "jenkins_password:*").each do |data_bag|
  jenkins_user data_bag['id'] do
    full_name data_bag['full_name']
    email     data_bag['email']
    password  data_bag['jenkins_password'] # TODO PLAIN TEXT SUCKS
  end
end
