#
# Cookbook Name:: jenkins
# Recipe:: backup
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

# Backup jenkins main directory
jenkins_directory = "/var/lib/jenkins"

# Backup data directory
backup_files      = [ jenkins_directory ]

# Ignore those
backup_files_exclude = [
  ::File.join(jenkins_directory, 'jobs/*/workspace'),
  ::File.join(jenkins_directory, 'jobs/*/.talend-workspace'),
  ::File.join(jenkins_directory, 'jobs/*/builds')
]

backup_name = "jenkins"

backup backup_name do
  cookbook "imos_backup"
  params ({
    :files         => backup_files,
    :files_exclude => backup_files_exclude
  })
end
