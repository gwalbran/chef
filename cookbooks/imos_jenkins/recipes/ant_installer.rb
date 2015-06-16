jenkins_script 'ant autoinstaller' do
  command <<-GROOVY
    import jenkins.model.*
    import hudson.tasks.Ant.*
    import hudson.tools.InstallSourceProperty

    def requiredAntVersions = #{node['imos_jenkins']['ant']['versions']}

    def extensions = Jenkins.instance.getExtensionList(hudson.tasks.Ant.DescriptorImpl.class)[0]
    def antInstallations = (extensions.installations as List)

    def installedAntVersions = antInstallations.collect { it.getName() }

    def antVersionsToInstall = requiredAntVersions - installedAntVersions

    if (!antVersionsToInstall.isEmpty()) {
      def newAntInstallations = antInstallations
      antVersionsToInstall.each { antVersion -> 
        println "Installing ${antVersion}"
        def antAutoInstaller = new hudson.tasks.Ant.AntInstaller(antVersion)
        def installProperty = new InstallSourceProperty([antAutoInstaller])
        def autoInstallation = new hudson.tasks.Ant.AntInstallation(antVersion, "", [installProperty])
        newAntInstallations.add(autoInstallation)
      }
      extensions.installations = newAntInstallations
      extensions.save()
    }
    GROOVY
end
