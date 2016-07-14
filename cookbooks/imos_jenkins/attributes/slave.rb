# Slave attributes
default['imos_jenkins']['slave']['directory'] = "/home/jenkins/slave"
default['imos_jenkins']['slave']['logdir']    = "/var/log/jenkins"
default['imos_jenkins']['slave']['name']      = nil
default['imos_jenkins']['slave']['secret']    = nil

default['imos_jenkins']['slave']['remote_fs'] = "/home/jenkins"
default['imos_jenkins']['slave']['executors'] = 1
default['imos_jenkins']['slave']['labels']    = []
