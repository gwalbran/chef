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

default['imos_jenkins']['s3']['credentials_databag'] = 'aws'
default['imos_jenkins']['s3']['credentials_databag_dev'] = 'aws-dev'

default['imos_jenkins']['node_common']['packages'] = [
    'checkinstall',
    'expat',
    'firefox',
    'shunit2',
    'zip'
]

default['imos_jenkins']['plugins'] = [
    'build-name-setter',
    'build-pipeline-plugin',
    'copyartifact',
    'grails',
    'envinject',
    'git',
    'git-client',
    'hipchat',
    'repository',
    'greenballs',
    'postbuildscript',
    'job-log-logger-plugin',
    'maven-plugin',
    'role-strategy',
    's3',
    'ssh-slaves',
    'throttle-concurrents',
    'xvfb',
    'token-macro',
    'ws-cleanup',
    'validating-string-parameter'
]

default['imos_jenkins']['node_common']['python_packages'] = [
  'awscli',
  'xmltodict'
]
