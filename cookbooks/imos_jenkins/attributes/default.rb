default['imos_jenkins']['user']                  = 'jenkins'
default['imos_jenkins']['group']                 = 'jenkins'
default['imos_jenkins']['ajp_port']              = 49187
default['imos_jenkins']['master_url']            = "https://jenkins.aodn.org.au/"
default['imos_jenkins']['master']['jvm_options'] = '-Xmx2G'
default['imos_jenkins']['master']['ssh_port']    = 2222
default['imos_jenkins']['master']['home']        = '/home/jenkins'
default['imos_jenkins']['git']['clone_timeout'] = 20
default['imos_jenkins']['xvfb']['path']         = '/usr/bin'

# Global environment settings for master
default['imos_jenkins']['username']  = "jenkins"

# SCM repo settings
default['imos_jenkins']['scm_repo'] = 'git@github.com:aodn/ci-config.git'

default['imos_jenkins']['s3cmd']['config_file'] = ::File.join(node['jenkins']['master']['home'], ".s3cfg")

default['imos_jenkins']['monitored_jobs'] = []

default['imos_jenkins']['node_common']['packages'] = [
    'checkinstall',
    'expat',
    'firefox',
    'shunit2',
    'zip'
]

default['imos_jenkins']['plugins'] = {
    'build-name-setter' => '1.6.5',
    'build-pipeline-plugin' => '1.5.4',
    'copyartifact' => '1.38.1',
    'grails' => '1.7',
    'envinject' => '1.93.1',
    'git' => '3.0.1',
    'git-client' => '2.1.0',
    'hipchat' => '2.0.0',
    'repository' => '1.3',
    'greenballs' => '1.15',
    'postbuildscript' => '0.17',
    'job-log-logger-plugin' => '1.0',
    'maven-plugin' => '2.7.1',
    'role-strategy' => '2.3.2',
    's3' => '0.10.10',
    'ssh-slaves' => '1.9',
    'throttle-concurrents' => '1.9.0',
    'xvfb' => '1.1.3',
    'token-macro' => '2.0',
    'ws-cleanup' => '0.32',
    'validating-string-parameter' => '2.3'
}

default['imos_jenkins']['node_common']['python_packages'] = [
  'awscli',
  'xmltodict'
]
