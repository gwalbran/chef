#########################
# backup rock overrides #
#########################
# Base directory for backups
# TODO preferablly should match the home directory of the backups user in its
# databag
default[:backup][:base_dir]   = "/var/backups"
default[:backup][:backup_dir] = ::File.join(node[:backup][:base_dir], "backups")
default[:backup][:backups_to_keep] = 1

# backups username and group
default[:backup][:username] = 'backups'
default[:backup][:group]    = 'backups'

##########################
# imos_backup attributes #
##########################

# When to start backups?
default[:imos_backup][:cron][:minute]  = 0
default[:imos_backup][:cron][:hour]    = 0
default[:imos_backup][:cron][:day]     = '*'
default[:imos_backup][:cron][:month]   = '*'
default[:imos_backup][:cron][:weekday] = '*'

# We have tight space constraints on most server, so get backup rock to use a
# different temporary directory
# And also make sure the temporary directory is on the same filesystem as the
# backup dir as we're going to use mv to move around backups from the temporary
# directory to the backup directory
default[:imos_backup][:tmp_dir] = ::File.join(node[:backup][:backup_dir], "..", "tmp")

# Directory in which we'll store backup status
default[:imos_backup][:status_dir] = ::File.join(node[:backup][:base_dir], "status")

# Lock file for pgsql backups, because they may take too long
default[:imos_backup][:lock_dir] = ::File.join(node[:backup][:base_dir], "lock")
default[:imos_backup][:imos_pgsql_lock_file] = ::File.join(node[:imos_backup][:lock_dir], "imos_pgsql.pid")

# Attribute used by nagios' check_backup, and should correspond to the cron
# scheduling you're running. If the backup is older than this amount of hours
# a nagios alert will fire even if the backup is completely fine
# So by default we'll go with 36 hours, which is a day and a half, since the
# default scheduling is to run once a day, this is a reasonable threshold
default[:imos_backup][:hours_valid_for] = 36

# S3 attributes
default[:imos_backup][:s3][:enable]            = false
default[:imos_backup][:s3][:password_data_bag] = "s3_imos_backups"
default[:imos_backup][:s3][:bucket]            = "imos-backups" # Need to omit the s3:// part
default[:imos_backup][:s3][:path]              = "backups"
default[:imos_backup][:s3][:config_file]       = ::File.join(node[:backup][:base_dir], "s3cfg")
