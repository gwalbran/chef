Overview
========
Some helper scripts to play around in the Chef/Vagrant environment.

### macos-setup.sh

### chef-sync.sh

Synchronizes all Chef objects with the chef server (using berkshelf and knife).

### vagrant-provision.sh

Quickly provision a vagrant machine.

Provision machine with virtualbox (default):

	$ bin/vagrant-provision.sh -p virtualbox imos-5.aodn.org.au

Provision a machine and delete after operation completed (remove the VM):

	$ bin/vagrant-provision.sh -c imos-6.aodn.org.au

For a Jenkins job which spawns machines on Nectar, you can run:

	$ NODE_NAME=imos-7.aodn.org.au
	$ export VAGRANT_OPENSTACK_KEYPAIR_NAME=...
	$ export VAGRANT_OPENSTACK_USERNAME=...
	$ export VAGRANT_OPENSTACK_API_KEY=...
	$ export BERKSHELF_PATH=${WORKSPACE}/.berkshelf
	$ bin/vagrant-provision.sh -c -r 3 -p openstack $NODE_NAME

