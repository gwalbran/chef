# Overview

This chef repository contains all cookbooks used for the IMOS infrastructure.

# Getting Started

## Prerequisites

| software | version | install notes |
|----------|---------|---------------|
|git  | | `apt-get` |
|ruby | >= 1.9.3 | `apt-get` / [`rbenv`](https://github.com/sstephenson/rbenv) |
|bundler |  | `gem` |
|[vagrant](http://www.vagrantup.com) | >= 1.6.3 | Download package from website |
|[Berkshelf](http://berkshelf.com/) | >= 3.1.0 | `gem` |
|[chef_dk](http://downloads.getchef.com/chef-dk/)| >= 0.3.5 | Install for your own distribution |
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
`private/`. This repository will contain only private data which should not be
exposed to the world. The way to do it is:
```
$ git clone git@github.com:YOUR_ORG/chef-private.git private
```

The symbolic links should look lively now.

Run up a node with Vagrant
--------------------------

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
