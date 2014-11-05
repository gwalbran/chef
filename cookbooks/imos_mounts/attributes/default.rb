default['mounts']['fstype']     = 'nfs'
default['mounts']['options']    = '_netdev,defaults,noatime,hard,intr,rw'
default['mounts']['ebs_device'] = "/dev/mapper/ebs-1"

# Default server for NSP NFS mounts
default['mounts']['nsp_nfs_server'] = "128.250.5.4"

# This is the internal address for 6-nsp-mel
default['mounts']['opendap_nfs_server'] = "192.168.100.60"

# SSHFS options for mounting
default['imos_mounts']['sshfs']['user']    = "sshfs"
default['imos_mounts']['sshfs']['options'] = "_netdev,users,idmap=user,IdentityFile=/home/#{node['imos_mounts']['sshfs']['user']}/.ssh/id_rsa,allow_other,reconnect,NumberOfPasswordPrompts=0,UserKnownHostsFile=/dev/null,StrictHostKeyChecking=no"
