name             "rsync_chroot"
maintainer       "Dan Fruehauf"
maintainer_email "malkodan@gmail.com"
license          "Apache 2.0"
description      "Installs/Configures rsync with chroot per ssh key"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "1.0.0"

supports 'debian'
supports 'ubuntu'
supports 'centos'
supports 'redhat'
supports 'amazon'
supports 'fedora'

recipe 'rsync_chroot::default', 'Installs rsync'
