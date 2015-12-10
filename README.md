# Overview

This chef repository contains all cookbooks used for the IMOS infrastructure.

# Getting Started

## Prerequisites

| software | version | install notes |
|----------|---------|---------------|
|git  | | `apt-get` |
|ruby | >= 1.9.3 | `apt-get` / [`rbenv`](https://github.com/sstephenson/rbenv) |
|bundler |  | `gem` |
|[vagrant](http://www.vagrantup.com) | >= 1.7.4 | Download package from website |
|[chef_dk](http://downloads.getchef.com/chef-dk/)| >= 0.6.0 | Install for your own distribution |
|[vagrant-berkshelf](https://github.com/berkshelf/vagrant-berkshelf) | >= 4.0.1 | `vagrant plugin install vagrant-berkshelf` |
|[VirtualBox](https://www.virtualbox.org/wiki/Downloads) |  | `apt-get` |

*See websites or documentation for more detailed insallation instructions*

Once you have all the above prerequisites, you can install all the ruby modules using:
```
$ bundle install
```

You will have to **uninstall** the berkshelf gem, as you should use the one from chef_dk:
```
$ gem uninstall berkshelf
```

## Optional Vagrant Plugins

*Note*: in addition to the vagrant plugins listed above, the following are worth a look:

* [vagrant-vbguest](https://github.com/dotless-de/vagrant-vbguest)
* [vagrant-cachier](http://fgrehm.viewdocs.io/vagrant-cachier)

# Private Repository

You may have noticed that `data_bags`, `roles` and `nodes` are referencing
`private/SOMETHING`. We'll need to plug a chef private repository under
`private/`. `private-sample` contains a sample tree structure with a few basic
definitions so you can get started. In order to use the sample definitions,
link it as shown below:
```
$ ln -s private-sample private
```

The symbolic links should look lively now.

**In case you plan on using real infrastructure, it is advised to create a new
private repository just with the private definitions and link `private` to it.**

## Private Sample Repository (Project Officer box etc)

[Click here for Project Officer box documentation](doc/README.po-box.md)

Read more [here](doc/README.examples.md) for more examples of nodes and how to
use them.

## Run up a node with Vagrant

Running up a VM should be as simple as:
```
$ vagrant up <node_name>
```

You can now ssh to the new VM:
```
$ vagrant ssh <node_name>
```

or check the status:
```
$ vagrant status <node_name>
```

The [Vagrantfile](Vagrantfile) contains some other overridable options - refer to *it* to see what they are.

## Packing Your Own Vagrant Basebox (with Packer)

To build a basebox using packer, you'll need [packer](http://www.packer.io)
version 0.8.0 or greater. From the `chef` directory you can then run:
```
$ berks vendor private/packer/cookbooks1
$ cp -a cookbooks private/packer/cookbooks2
$ cd private/packer && packer build basebox.json
```

# Workflow

If you wish to contribute to this repository, you will have to fork it.

Before doing any new work, you should create a new branch:
```
$ git co -b new_feature
```

Work on the branch as needed, then push it:
```
$ git push origin new_feature
```

Submit a PR and see if we accept it.

## Testing
### Unit Testing
`chefspec` unit tests can be run either from the root:

```
$ chef exec rake spec
```

or from a particular cookbook directory, e.g.:

```
$ cd cookbooks/imos_po
$ chef exec rspec spec
```
