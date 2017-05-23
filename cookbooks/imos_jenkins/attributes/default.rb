default['imos_jenkins']['user']                  = 'jenkins'
default['imos_jenkins']['group']                 = 'jenkins'
default['imos_jenkins']['ajp_port']              = 49187
default['imos_jenkins']['master_url']            = "https://jenkins.aodn.org.au/"
default['imos_jenkins']['master']['jvm_options'] = '-Xmx2G -Dhudson.model.ParametersAction.keepUndefinedParameters=true -Djenkins.install.runSetupWizard=false'
default['imos_jenkins']['master']['ssh_port']    = 2222
default['imos_jenkins']['master']['home']        = '/home/jenkins'
default['imos_jenkins']['git']['clone_timeout'] = 20
default['imos_jenkins']['xvfb']['path']         = '/usr/bin'

# Global environment settings for master
default['imos_jenkins']['username']  = "jenkins"

# SCM repo settings
default['imos_jenkins']['scm_repo'] = 'git@github.com:aodn/ci-config.git'
default['imos_jenkins']['scm_email'] = 'developers@emii.org.au'
default['imos_jenkins']['scm_user'] = 'aodn-ci'

default['imos_jenkins']['s3cmd']['config_file'] = ::File.join(node['jenkins']['master']['home'], ".s3cfg")

default['imos_jenkins']['monitored_jobs'] = []

default['imos_jenkins']['s3']['credentials_databag'] = 'jenkins'
default['imos_jenkins']['s3']['credentials_databag_dev'] = 'aws-dev'

default['imos_jenkins']['node_common']['packages'] = [
    'checkinstall',
    'expat',
    'firefox',
    'shunit2',
    'zip'
]
# this is to fix an issue brought about by a change in Ruby versioning.
# The issue will need to be fixed in the opscode jenkins cookbook. There's a bug logged.
#TODO: Remove this when the issue has been fixed and we've updated to the fixed jenkins cookbook
class Chef::Provider::JenkinsPlugin
  alias old_plugin_version plugin_version
  def plugin_version(version)
    return version if version == "1.0-beta-1"

    old_plugin_version(version)
  end
end

default['imos_jenkins']['plugins'] = {
    'mailer' => '	1.20',
    'credentials' => '2.1.13',
    'ssh-credentials' => '1.13',
    'ssh-slaves' => '1.17',
    'build-name-setter' => '1.6.5',
    'build-pipeline-plugin' => '1.5.6',
    'copyartifact' => '1.38.1',
    'envinject' => '2.1',
    'git' => '3.3.0',
    'git-client' => '2.4.5',
    'repository' => '1.3',
    'maven-plugin' => '2.15.1',
    'role-strategy' => '2.4.0',
    's3' => '0.10.12',
    'throttle-concurrents' => '2.0',
    'xvfb' => '1.1.3',
    'token-macro' => '2.1',
    'ws-cleanup' => '0.33',
    'validating-string-parameter' => '2.3',

}

default['imos_jenkins']['node_common']['python_packages'] = [
  'awscli',
  'xmltodict'
]


