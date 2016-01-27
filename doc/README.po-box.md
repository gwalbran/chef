# PO Box

## What is it?

Intended for Project Officers (PO), this box is a utility box for data
scientists at IMOS and contains a full stack of the IMOS portal and more
goodies:
 * Portal
 * Geonetwork
 * Geoserver (data directory is at `shared_src/geoserver`)
 * Postgres DB + schemas for loading data
 * Restore capabilities
 * Full pipeline processing

To run the PO Box, cd to your chef directory and run:
```
$ bin/po-box.sh
```

To halt the PO Box:
```
$ bin/po-box.sh halt
```

The services mentioned will be exposed on 10.11.12.13, or po.aodn.org.au.
Relevant links are:
 * http://po.aodn.org.au/imos123
 * http://po.aodn.org.au/geonetwork
 * http://po.aodn.org.au/geoserver
 * Postgres
   * Host: po.aodn.org.au
   * Port: 5432
   * Login: admin
   * Password: admin

Running restores can be done by tinkering with `nodes/po.json`, under the
`imos_backup/restore` area. After modifying it you must run:
```
$ bin/po-box.sh
```

In order to initiate a restore, run:
```
$ vagrant ssh po -- sudo /var/backups/restore/restore.sh
```

## Testing Pipeline Processing

Pipeline processing refers to the event driven infrastructure which polls files
entering the ftp/rsync incoming directory.

In order to upload files into the incoming directories rsync has to be used
with the following credentials:
 * Host: po.aodn.org.au
 * User: incoming
 * Password: incoming
 * Destination: ::incoming

For example:
```
$ export RSYNC_PASSWORD=incoming
$ rsync file.nc incoming@po.aodn.org.au::incoming/ANMN/AM/
```

The log file will be exposed under `src/data-services/log/process.log`:
```
$ tail -f src/data-services/log/process.log
```

Error files will be moved to `src/error` (directory will be created automatically):
```
$ ls -l src/error/
```

## Deploying Harvesters Not From Jenkins

Data bag definitions for deploying harvesters are at `data_bags/talend/`:
```
$ ls -l data-bags/talend/
```

By default harvesters will be deployed from Jenkins using the job defined at
`node['talend']['jenkins_job']` or what is defined in the talend data bag like:
```
$ cat data_bags/talend/acorn_radial_nonqc.json
{
    "id": "acorn_radial_nonqc",
    "artifact_filename": "ACORN_radial_nonQC_harvester_Latest.zip",
    "event": {
        "regex": [
            "^IMOS/ACORN/radial/.*/.*FV00_radial\\.nc$"
        ]
    }
}
```

In order to deploy harvesters build from TOS, simply export them as a zip file,
then place them in your `chef` directory, or in `chef/tmp` and modify the
corresponding data bag to deploy the file directly (edit
`data_bags/talend/acorn_radial_nonqc.json`):
```
{
    "id": "acorn_radial_nonqc",
    "artifact_id": "/vagrant/tmp/ACORN_radial_nonQC_harvester_1.0.zip",
    "event": {
        "regex": [
            "^IMOS/ACORN/radial/.*/.*FV00_radial\\.nc$"
        ]
    }
}
```

Notice `artifact_filename` becomes `artifact_id`. `/vagrant` will point to the
root of your chef repository, so in your chef directory you are expected to
have:
```
[user@host chef]$ ls -l tmp/ACORN_radial_nonQC_harvester_1.0.zip 
-rw-------  1 dan  dan  17416021 Oct  9 11:56 tmp/ACORN_radial_nonQC_harvester_1.0.zip
```

Alternatively, you can use the `bin/talend-local.rb` utility to do the same:
```
$ bin/talend-local.rb data_bags/talend/acorn_radial_nonqc.json tmp/ACORN_radial_nonQC_harvester_1.0.zip
```

Then you need to deploy the harvester running:
```
$ vagrant provision po
```

## Importing Geonetwork Records

By default, po box can import from https://catalogue-123.aodn.org.au/geonetwork

Initiate the import by running:
```
$ vagrant ssh po -- /var/lib/tomcat7/default/import-gn-geonetwork.sh
```
