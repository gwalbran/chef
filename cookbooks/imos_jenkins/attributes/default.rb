default['imos_jenkins']['user']                  = 'jenkins'
default['imos_jenkins']['group']                 = 'jenkins'
default['imos_jenkins']['ajp_port']              = 49187
default['imos_jenkins']['master_url']            = "https://jenkins.aodn.org.au/"
default['imos_jenkins']['master']['jvm_options'] = '-Xmx2G'
default['imos_jenkins']['master']['ssh_port']    = 2222
default['imos_jenkins']['master']['home']        = '/home/jenkins'

default['imos_jenkins']['maven']['versions']    = [ "3.2.2" ]
default['imos_jenkins']['grails']['versions']   = [ "1.3.7", "2.1.0", "2.2.0", "2.4.4" ]
default['imos_jenkins']['ant']['versions']      = [ "1.8.4" ]
default['imos_jenkins']['git']['clone_timeout'] = 20
default['imos_jenkins']['xvfb']['path']         = '/usr/bin'

# Global environment settings for master
default['imos_jenkins']['username']  = "jenkins"
default['imos_jenkins']['email']     = node['email_contact'] || "root@localhost"
default['imos_jenkins']['executors'] = node['cpu']['total'] ? (node['cpu']['total']).to_i : 2

# SCM repo settings
default['imos_jenkins']['scm_repo'] = 'git@github.com:aodn/ci-config.git'

default['imos_jenkins']['s3cmd']['config_file'] = ::File.join(node['jenkins']['master']['home'], ".s3cfg")

default['imos_jenkins']['monitored_jobs'] = []
