default['imos_logstash']['server']['domain'] = 'aodn.org.au'

default['imos_logstash']['indexer']['host'] = "logstash.#{node['imos_logstash']['server']['domain']}"

default['imos_logstash']['indexer']['lumberjack']['port'] = 9000
default['imos_logstash']['indexer']['lumberjack']['ssl_key_path'] = File.join(node['logstash']['instance']['default']['basedir'], 'ssl', 'logstash-agent.key')
default['imos_logstash']['indexer']['lumberjack']['ssl_cert_path'] = File.join(node['logstash']['instance']['default']['basedir'], 'ssl', 'logstash-agent.crt')

default['imos_logstash']['kibana']['host'] = "kibana.#{node['imos_logstash']['server']['domain']}"
default['imos_logstash']['kibana']['user_groups'] = [ "admin", "projectofficer" ]
