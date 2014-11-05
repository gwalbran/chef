# Overview
This chef repository contains some, but not all (some is still being migrated from puppet), of the configuration to provision the eMII infrastructure.


# Getting Started

## Prerequisites

| software | version | install notes |
|----------|---------|---------------|
git |  | `apt-get`
ruby |  | `apt-get` / [`rbenv`](https://github.com/sstephenson/rbenv)
bundler |  | `gem`
[vagrant](http://www.vagrantup.com) | >= 1.5.2 | Download package from website
[Berkshelf](http://berkshelf.com/) | >= 3.1.0 | `gem`
[vagrant-berkshelf](https://github.com/berkshelf/vagrant-berkshelf) | >= 2.0.1 | `vagrant plugin install vagrant-berkshelf --plugin-version 2.0.1`
[VirtualBox](https://www.virtualbox.org/wiki/Downloads) |  | `apt-get`

*See websites or documentation for more detailed insallation instructions*

# Vagrant

*Note*: in addition to the vagrant plugins listed above, the following are worth a look:

* [vagrant-vbguest](https://github.com/dotless-de/vagrant-vbguest)
* [vagrant-cachier](http://fgrehm.viewdocs.io/vagrant-cachier)

 

Run up a node with Vagrant
--------------------------

Running up a VM should be as simple as:

	$ vagrant up <node_name>

where `<node_name>` is the name of the node which you would like to run up, e.g.:

	$ vagrant up edge.aodn.org.au

will create a vagrant VM using VirtualBox as the provider and provision it according to the `edge` node definition. Alternatively, you may create and provision a Nectar VM as follows:

	$ vagrant up edge.aodn.org.au --provider=openstack

You can now ssh to the new VM:

    $ vagrant ssh edge.aodn.org.au

or check the status:

	$ vagrant status edge.aodn.org.au


The [Vagrantfile](Vagrantfile) contains some other overridable options - refer to *it* to see what they are.

# Workflow

Chef code lives in our Git repository at `git@github.com:aodn/chef.git`.
There is only one long-lived branch, `production`, which as its names suggests, is the branch that is pushed to the Chef server and that provides the Single Point Of Truth (SPOT rule) for our infrastructure.

Apart from emergency hotfixes, all work should be done on a feature branch and must be reviewed before being merged in to production (see [workflow](#Workflow)).


1. Get the latest production branch, and create a new topic branch from it:

		$ git checkout production
		$ git checkout -b amazing_new_feature

2. Hack some codes (including bumping cookbook version numbers, where appropriate)...
3. Test, e.g. using vagrant:

		$ vagrant up node_with_amazing_feature

4. Push to central repo:

		$ git push -u origin amazing_new_feature

5. Review (done by reviewer)…

		$ git checkout amazing_new_feature

6. Merge in to production and push (after possibly repeating steps 3-5) (again, done by reviewer):

		$ git checkout production
        $ git pull
		$ git merge amazing_new_feature
		$ git push

7. Bask in your own glory as the change is automatically propogated to production (by jenkins and chef-client jobs running on the production servers).
8. Clean up the branch from the remote repo when everything is good:

		$ git push origin :amazing_new_feature

# General info

Some more general info (about chef, jenkins, git etc) is available from our [intranet](http://intranet.emii.org.au/content/chef).
