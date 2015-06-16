default['imos_jenkins']['user']       = 'jenkins'
default['imos_jenkins']['group']      = 'jenkins'
default['imos_jenkins']['ajp_port']   = 49187
default['imos_jenkins']['master_url'] = "https://jenkins.aodn.org.au/"

default['imos_jenkins']['maven']['version']   = "3.2.2"
default['imos_jenkins']['grails']['versions'] = [ "1.3.7", "2.1.0", "2.2.0", "2.4.4" ]
default['imos_jenkins']['ant']['versions']    = [ "1.8.4" ]

# Global environment settings for master
default['imos_jenkins']['username']  = "jenkins"
default['imos_jenkins']['email']     = "sys.admin@emii.org.au"
default['imos_jenkins']['executors'] = node['cpu']['total'] ? (node['cpu']['total']).to_i : 2
