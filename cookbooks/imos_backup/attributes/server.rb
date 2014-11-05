# Backup server attributes

# How many backups to save on remote servers?
default[:imos_backup][:server][:backups_to_keep] = 14 # 2 weeks by default

# role set for backups, we'll search for all the nodes with this attributes
# when pulling backups
default[:imos_backup][:role] = "backup"
