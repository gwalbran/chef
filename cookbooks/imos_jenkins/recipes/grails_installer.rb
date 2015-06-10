jenkins_script 'grails autoinstaller' do
  command <<-GROOVY
    import jenkins.model.*
    import com.g2one.hudson.grails.*
    import hudson.tools.InstallSourceProperty

    def requiredGrailsVersions = #{node['imos_jenkins']['grails']['versions']}

    def extensions = Jenkins.instance.getExtensionList(com.g2one.hudson.grails.GrailsInstallation.DescriptorImpl.class)[0]
    def grailsInstallations = (extensions.installations as List)

    def installedGrailsVersions = grailsInstallations.collect { it.getName() }

    def grailsVersionsToInstall = requiredGrailsVersions - installedGrailsVersions

    if (!grailsVersionsToInstall.isEmpty()) {
      def newGrailsInstallations = grailsInstallations
      grailsVersionsToInstall.each { grailsVersion ->
        println "Installing ${grailsVersion}"
        def grailsAutoInstaller = new GrailsInstaller(grailsVersion)
        def installProperty = new InstallSourceProperty([grailsAutoInstaller])
        def autoInstallation = new GrailsInstallation(grailsVersion, "", [installProperty])
        newGrailsInstallations.add(autoInstallation)
      }
      extensions.installations = newGrailsInstallations
      extensions.save()
    }
    GROOVY
end
