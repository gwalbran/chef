#
# authentication
#

def configure_jenkins_security
  # Create the 'chef' user with the public key
  public_key = Chef::Recipe::JenkinsHelper.get_key_pair()[:public_key]
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

      // Set SSH port
      def sshExtension = instance.getExtensionList(org.jenkinsci.main.modules.sshd.SSHD.class)[0]
      sshExtension.setPort(#{node['imos_jenkins']['master']['ssh_port'].to_i})

      instance.save()
    EOH
  end
end

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
