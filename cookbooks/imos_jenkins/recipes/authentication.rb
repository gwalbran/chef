#
# authentication
#

require 'openssl'
require 'net/ssh'

def get_key_pair
  ssh_private_key = Chef::EncryptedDataBagItem.load("users", "chef")['ssh_private_key']
  key = OpenSSL::PKey::RSA.new(ssh_private_key)
  private_key = key.to_pem
  public_key = "#{key.ssh_type} #{[key.to_blob].pack('m0')}"
  return { :private_key => private_key, :public_key => public_key }
end

def set_jenkins_creds
  # Set the private key on the Jenkins executor
  private_key = get_key_pair()[:private_key]
  node.run_state[:jenkins_private_key] = private_key
end

def configure_jenkins_security
  # Create the 'chef' user with the public key
  public_key = get_key_pair()[:public_key]
  jenkins_user 'chef' do
    full_name 'chef system user'
    public_keys [public_key]
  end

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
end

# At the first run, we must not use credentials for setting this security
# settings, subsequent runs should use it. Here we first try without having
# any credentials set (as if it a first run) and then we try setting credentials
# and continue on if it succeeded
# If we're on vagrant, save us all of this security headache altogether.
if ! node['vagrant']
  set_jenkins_creds
  configure_jenkins_security
end

# Until https://github.com/opscode-cookbooks/jenkins/pull/233 is merged, use
# this mechanism to define users with SHA passwords
def jenkins_user_sha(id, full_name, email, password)
  Chef::Log.info "Defining Jenkins user '#{id}' with '#{password}'"

  jenkins_script "user_add_#{id}" do
    command <<-EOH.gsub(/^ {4}/, '')
      user = hudson.model.User.get('#{id}')
      user.setFullName('#{full_name}')
      email = new hudson.tasks.Mailer.UserProperty('#{email}')
      user.addProperty(email)
      password = hudson.security.HudsonPrivateSecurityRealm.Details.fromHashedPassword('#{password}')
      user.addProperty(password)
    EOH
  end
end

# Define all jenkins users
search('users', "jenkins_password:*").each do |data_bag|
  jenkins_user_sha(data_bag['id'], data_bag['full_name'], data_bag['email'], data_bag['jenkins_password'])
  #jenkins_user data_bag['id'] do
  #  full_name data_bag['full_name']
  #  email     data_bag['email']
  #  password  data_bag['jenkins_password'] # TODO PLAIN TEXT SUCKS
  #end
end
