# Overview

This repository contains a few node definitions which can be used with the IMOS
chef repository at https://github.com/aodn/chef

# Getting Started

## Prerequisites

https://github.com/aodn/chef/blob/master/README.md#prerequisites

## Boxes

### PO Box

Intended for Project Officers (PO), this box is a utility box for data
scientists at IMOS and contains a full stack of the IMOS portal and more
goodies:
 * Portal
 * Geonetwork
 * Geoserver (data directory is at `shared_src/geoserver`)
 * Postgres DB + schemas for loading data
 * Restore capabilities

To run the PO Box, cd to your chef directory and run:
```
$ private/bin/po-box.sh
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
$ private/bin/po-box.sh
```

In order to initiate a restore, run:
```
$ vagrant ssh po -- sudo /var/backups/restore/restore.sh
```

### Testing Pipeline Processing

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

### Dev Box

Intended for development and debugging of various IMOS web applications such as:
 * Portal
 * AATAMS
 * AUV
 * Acoustic Data Viewer
 * GoGoDuck
 * Geoserver (runs in tomcat container)
 * Geonetwork (runs in tomcat container)

To run the dev Box, cd to your chef directory and run:
```
$ vagrant up dev
```

The application you wish to develop needs to be available at `src/APP_NAME`,
for portal for instance do the following:
```
$ mkdir -p src && cd src && git clone git@github.com:aodn/aodn-portal
```

Login and run any of the applications listed above with:
```
$ vagrant ssh dev
$ portal_run         # runs portal
$ portal_test        # runs portal tests
$ portal_test -rerun # runs portal tests with the -rerun option
$ auv_run            # runs AUV
$ gogoduck           # change directory to the gogoduck web app
```

Although the dev box has a full IMOS stack (portal, geonetwork, geoserver),
rigging them to work together requires some mocking in `/etc/hosts`. This
README assumes you know how to do it since you are a programmer.

Happy development!

### Systest Box

This is a fully contained box which includes the whole stack and is intended
for transient system testing.

To run:
```
$ vagrant up systest
```

### Packer

To build a basebox using packer, you'll need [packer](http://www.packer.io)
version 0.8.0 or greater. From the `chef` directory you can then run:
```
$ berks vendor private/packer/cookbooks1
$ cp -a cookbooks private/packer/cookbooks2
$ cd private/packer && packer build basebox.json
```
