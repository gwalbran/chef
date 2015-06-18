define :imos_jenkins_user_jbcrypt do
  id        = @params[:id]
  full_name = @params[:full_name]
  email     = @params[:emails]
  password  = @params[:password]

  Chef::Log.info "Defining Jenkins user '#{id}' with hashed password '#{password}'"

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
