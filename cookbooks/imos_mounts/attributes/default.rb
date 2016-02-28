default['mounts']['fstype']     = 'nfs'
default['mounts']['options']    = '_netdev,defaults,noatime,hard,intr,rw'
default['mounts']['ebs_device'] = "/dev/mapper/ebs-1"

# SSHFS options for mounting
default['imos_mounts']['sshfs']['user']    = "sshfs"
default['imos_mounts']['sshfs']['options'] = "_netdev,users,idmap=user,IdentityFile=/home/#{node['imos_mounts']['sshfs']['user']}/.ssh/id_rsa,allow_other,reconnect,NumberOfPasswordPrompts=0,UserKnownHostsFile=/dev/null,StrictHostKeyChecking=no"

default['imos_mounts']['s3fs']['password_data_bag'] = nil
