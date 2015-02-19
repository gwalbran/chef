# Restoring can be dangerous, so do not allow it by default
default[:imos_backup][:restore][:allow] = false

# Where to take backups from when restoring
default[:imos_backup][:restore][:from_host] = "backups.aodn.org.au"

default[:imos_backup][:restore][:directives] = []

# User to use for restoration coming from remote server
default[:imos_backup][:restore][:username] = "restore"

# SSH options for restoring
default[:imos_backup][:restore][:ssh_opts] = ""
