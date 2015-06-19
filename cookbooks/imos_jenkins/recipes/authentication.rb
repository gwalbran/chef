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

  admin_users = [ 'chef' ]
  search('users', "jenkins_password:*").each do |data_bag|
    admin_users << data_bag['id']
  end

  jenkins_script 'setup authentication' do
    command <<-EOH.gsub(/^ {4}/, '')
      import jenkins.model.*
      import hudson.security.*
      import com.michelin.cio.hudson.plugins.rolestrategy.*

      def adminUsers = #{admin_users}

      def createAdminRole(strategy) {
          Set<Permission> permissions = new HashSet<Permission>()
          for(PermissionGroup group : strategy.DESCRIPTOR.getGroups(strategy.GLOBAL)) {
              for(Permission permission : group) {
                  permissions.add(permission)
              }
          }
          return new Role("admin", permissions)
      }

      def handleAnonymousRole(strategy) {
          Set<Permission> permissions = new HashSet<Permission>()
          permissions.add(PermissionGroup.get(hudson.model.Hudson).find("Read"))

          // User anonymous should have global read access
          def anonymousRole = new Role("anonymous", permissions)
          strategy.addRole(strategy.GLOBAL, anonymousRole)
          strategy.assignRole(strategy.GLOBAL, anonymousRole, "anonymous")
      }

      def instance = Jenkins.getInstance()
      def realm = new HudsonPrivateSecurityRealm(false)
      instance.setSecurityRealm(realm)
      def strategy = new RoleBasedAuthorizationStrategy()

      def adminRole = createAdminRole(strategy)
      strategy.addRole(strategy.GLOBAL, adminRole)

      adminUsers.each { user ->
          strategy.assignRole(strategy.GLOBAL, adminRole, user)
      }

      handleAnonymousRole(strategy)

      instance.setAuthorizationStrategy(strategy)
      instance.save()
    EOH
  end
end

set_jenkins_creds
configure_jenkins_security

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
