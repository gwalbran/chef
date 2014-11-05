backup Cookbook
=================
This cookbook takes care of backups in IMOS.

Requirements
------------
Requires the backup rock cookbook and a few others.

This cookbook relies on backup rock found here:
https://github.com/danfruehauf/backup

Attributes
----------

#### backup::default
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>[:imos_backup][:cron][:minute]</tt></td>
    <td>String</td>
    <td>Minute for backup cronjob</td>
    <td><tt>0</tt></td>
  </tr>
  <tr>
    <td><tt>[:imos_backup][:cron][:hour]</tt></td>
    <td>String</td>
    <td>Hour for backup cronjob</td>
    <td><tt>0</tt></td>
  </tr>
  <tr>
    <td><tt>[:imos_backup][:cron][:day]</tt></td>
    <td>String</td>
    <td>Day for backup cronjob</td>
    <td><tt>*</tt></td>
  </tr>
  <tr>
    <td><tt>[:imos_backup][:cron][:month]</tt></td>
    <td>String</td>
    <td>Month for backup cronjob</td>
    <td><tt>*</tt></td>
  </tr>
  <tr>
    <td><tt>[:imos_backup][:cron][:weekday]</tt></td>
    <td>String</td>
    <td>Week day for backup cronjob</td>
    <td><tt>*</tt></td>
  </tr>
  <tr>
    <td><tt>[:imos_backup][:tmp_dir]</tt></td>
    <td>String</td>
    <td>Temporary directory for backup</td>
    <td><tt>File.join(node[:backup][:backup_dir], "..", "tmp")</tt></td>
  </tr>
  <tr>
    <td><tt>[:imos_backup][:status_dir]</tt></td>
    <td>String</td>
    <td>Status dir for backups, nagios will read from here</td>
    <td><tt>#{node[:backup][:base_dir]}/status</tt></td>
  </tr>

  <tr>
    <td><tt>[:imos_backup][:lock_dir]</tt></td>
    <td>String</td>
    <td>Lock directory for backups (pgsql uses this directory to prevent multiple backups running at the same time</td>
    <td><tt>File.join(node[:backup][:base_dir], "lock")</tt></td>
  </tr>
  <tr>
    <td><tt>[:imos_backup][:imos_pgsql_lock_file]</tt></td>
    <td>String</td>
    <td>IMOS pgsql backup module lock file, to prevent multiple backups running at the same time</td>
    <td><tt>File.join(node[:imos_backup][:lock_dir], "imos_pgsql.pid")</tt></td>
  </tr>
  <tr>
    <td><tt>[:imos_backup][:hours_valid_for]</tt></td>
    <td>Integer</td>
    <td>Number of hours before declaring a backup too old (for nagios monitoring)</td>
    <td><tt>36</tt></td>
  </tr>
</table>

#### backup::server

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>[:backup][:server][:backups_to_keep]</tt></td>
    <td>Integer</td>
    <td>Number of backups to leave on backup server</td>
    <td><tt>7</tt></td>
  </tr>
  <tr>
    <td><tt>[:backup][:role]</tt></td>
    <td>String</td>
    <td>Name of role of backup nodes when a server is searching for them</td>
    <td><tt>backup</tt></td>
  </tr>
</table>

#### backup::restore

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>[:imos_backup][:restore][:allow]</tt></td>
    <td>Boolean</td>
    <td>Enable/disable restore functionality</td>
    <td><tt>false</tt></td>
  </tr>
  <tr>
    <td><tt>[:imos_backup][:restore][:from_host]</tt></td>
    <td>String</td>
    <td>Host to download backups from</td>
    <td><tt>backups.aodn.org.au</tt></td>
  </tr>
  <tr>
    <td><tt>[:imos_backup][:restore][:directives]</tt></td>
    <td>Array</td>
    <td>Restore directives, see below</td>
    <td><tt>[]</tt></td>
  </tr>
  <tr>
    <td><tt>[:imos_backup][:restore][:username]</tt></td>
    <td>String</td>
    <td>Username to use on remote server when pulling backups for restore</td>
    <td><tt>restore</tt></td>
  </tr>
</table>

Usage
-----

#### backup::default
As a backup client, make sure your node definition have the `backup` role,
which will include the `backup::default` recipe. If you have any backups
planned in your recipe, probe for the backup role on the node and proceed if it
is set:
```
if node.run_list.roles.include?('backup')
  # YOUR BACKUP DEFINITIONS HERE
end
```

To create a simple backup for an application, use the following:
```
# Backup schnitzel database with username chicken and password tikka
backup_databases = [{
  'name'     => 'schnitzel',
  'username' => 'chicken',
  'password' => 'tikka',
  'host'     => 'masala',
  'port'     => 5432
}]

# Backup /etc/monkey and /etc/zebra
# backup_files takes also directories and will operate on them recursively
backup_files = [ "/etc/monkey", "/etc/zebra" ]

# Let the backup name be 'pony'
backup 'pony' do
  display_name 'pony'
  databases    backup_databases
  files        backup_files
end
```

The above example explicitly uses the `default` backup model, found in
`templates/model_default.erb`. Should you require a more advanced type of
backup, you can write a new template, say `templates/model_knight.erb` and call
it with:
```
# Let the backup name be 'jedi'
backup 'jedi' do
  display_name 'jedi'
  model        'knight'
  weapon       'light sabre'
  friends      [ 'darth vader', 'yoda' ]
end
```

In your template you can then access ```@param[:weapon]``` and
```@param[:friends]``` to use your variables.

#### backup::server
Simply include `backup::server` in your run list. The rest happens like magic:
```json
{
  "name":"my_node",
  "run_list": [
    "recipe[backup::server]"
  ]
}
```

backup::server probes for all nodes in the chef server and will pull the
backups from them, then apply backup cycling when needed. Backup servers will
most likely have more disk space than regular nodes, so they can store more
backups compared to a puny node.

Nagios Integration
------------------
Each node will have in nagios a `backup` check which will hold the status of
the local backup on the node. The status is updated using Nagios NSCA.

A backup server on the other hand will have a simple `backup` check for
itself (if it backs up itself) and then a handful of other monitors for each
node it pulls backups from, such as:
 * backup imos-1.emii.org.au -> Status of backups from imos-1.emii.org.au
 * backup imos-2.emii.org.au -> Status of backups from imos-2.emii.org.au
 * backup abcdef.emii.org.au -> Status of backups from abcdef.emii.org.au

Restore
-------

`imos_backup` supports also restoring nodes. In order for that to happen you
need to have in your node definition something like:
```
"imos_backup": {
    "restore": {
        "allow": true,
        "directives": [{
            "from_host":  "3-nec-mel.emii.org.au",
            "from_model": "pgsql"
            "files":      [ "geonetwork/public.dump" ]
        }]
    }
}
```

This instructs the given node to setup restore for the pgsql backup model from
node `3-nec-mel.emii.org.au`. The `files` parameter is optional and will
instruct the backup fetching what files to fetch. If unspecified, the whole
backup will be downloaded.

Later on after the node boots you can run:
```
$ /mnt/ebs/backups/restore/restore.sh
```

This will trigger the restoration of the node.

License and Authors
-------------------
Authors:
 * Dan Fruehauf <dan.fruehauf@utas.edu.au>

