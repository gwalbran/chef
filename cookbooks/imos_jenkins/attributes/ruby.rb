# Attributes for building a ruby env for jenkins
default['imos_jenkins']['ruby']['version'] = '1.9.3-p392'
default['imos_jenkins']['ruby']['gems']    = [
  { 'name' => 'bundler' },
  { 'name' => 'rake' },
  { 'name' => 'thor' },
  { 'name' => 'knife-solo' }
]
