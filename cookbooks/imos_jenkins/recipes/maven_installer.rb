jenkins_script 'add maven autoinstaller' do
  command <<-EOH.gsub(/^ {4}/, '')
    import jenkins.model.*
    import hudson.tasks.Maven.MavenInstallation
    import hudson.tasks.Maven.MavenInstaller
    import hudson.tools.InstallSourceProperty

    def extensions = Jenkins.instance.getExtensionList(hudson.tasks.Maven.DescriptorImpl.class)[0]
    def installations = (extensions.installations as List)

    if (installations.isEmpty()) {
        def mavenAutoInstaller = new MavenInstaller('3.2.2')
        def installProperty = new InstallSourceProperty([mavenAutoInstaller])
        def autoInstallation = new MavenInstallation('default', null, [installProperty])

        installations.add(autoInstallation)
        extensions.installations = installations
        extensions.save()
    }
    else {
        // Already configured.
    }
    EOH
end
