jenkins_script 'add maven autoinstaller' do
  command <<-GROOVY
    import jenkins.model.*
    import hudson.tasks.Maven.MavenInstallation
    import hudson.tasks.Maven.MavenInstaller
    import hudson.tools.InstallSourceProperty

    def extensions = Jenkins.instance.getExtensionList(hudson.tasks.Maven.DescriptorImpl.class)[0]
    def installations = (extensions.installations as List)

    if (installations.isEmpty()) {
      def mavenAutoInstaller = new MavenInstaller('#{node['imos_jenkins']['maven']['version']}')
      def installProperty = new InstallSourceProperty([mavenAutoInstaller])
      def autoInstallation = new MavenInstallation('default', null, [installProperty])

      installations.add(autoInstallation)
      extensions.installations = installations
      extensions.save()
    }
    else {
      // Already configured
    }
    GROOVY
end
