name             "imos_core"
maintainer       "IMOS"
maintainer_email "developers@emii.org.au"
license          "All rights reserved"
description      "Short recipes used at IMOS"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"

%w{
  logrotate
  sysctl
  cron
  build-essential
  git_ssh_wrapper
  unattended_upgrades
  sudo
}.each do |cookbook|
  depends cookbook
end
