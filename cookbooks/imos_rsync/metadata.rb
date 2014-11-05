name             "imos_rsync"
maintainer       "IMOS"
maintainer_email "developers@emii.org.au"
license          ""
description      "Installs/Configures rsync"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"

depends "rsync"
depends "rsync_chroot"
depends "logrotate"
