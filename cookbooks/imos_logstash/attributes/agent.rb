# Be nice if we could use %{LOGLEVEL} here, but it doesn't work.
# (see https://github.com/elasticsearch/logstash/blob/master/patterns/grok-patterns#L94)
default['imos_logstash']['agent']['loglevels'] = [ "TRACE", "DEBUG", "INFO", "WARN", "ERROR", "SEVERE", "FATAL" ]

default['imos_logstash']['agent']['probed_recipes'] = {
  'recipe[imos_jenkins::master]' => "imos_logstash::jenkins_agent",
  'recipe[imos_squid]' => "imos_logstash::squid_agent",
  'recipe[imos_webapps::generic_webapp]' => "imos_logstash::webapp_agent",
  'recipe[talend]' => "imos_logstash::talend_agent"
}
