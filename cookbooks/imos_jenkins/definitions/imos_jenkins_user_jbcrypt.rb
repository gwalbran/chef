define :imos_jenkins_user_jbcrypt do
  id          = @params[:id]
  full_name   = @params[:full_name]
  email       = @params[:emails]
  password    = @params[:password]

  public_keys = []
  if @params[:public_keys].kind_of?(Array)
    public_keys = @params[:public_keys]
  else
    public_keys = [ @params[:public_keys] ]
  end

  Chef::Log.info "Defining Jenkins user '#{id}' with hashed password '#{password}'"

  jenkins_script "user_add_#{id}" do
    command <<-EOH.gsub(/^ {4}/, '')
      def user = hudson.model.User.get('#{id}')
      user.setFullName('#{full_name}')
      def email = new hudson.tasks.Mailer.UserProperty('#{email}')
      user.addProperty(email)
      def password = hudson.security.HudsonPrivateSecurityRealm.Details.fromHashedPassword('#{password}')
      user.addProperty(password)
      def keys = new org.jenkinsci.main.modules.cli.auth.ssh.UserPropertyImpl('#{public_keys.join('\n')}')
      user.addProperty(keys)
    EOH
  end
end
