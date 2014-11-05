#
# Cookbook Name:: imos_core
# Recipe:: logrotate
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#

node.set['logrotate']['global'] = {
  'daily' => true,
  'weekly' => false,
  'rotate' => 28,
  'create' => '',
  'size' => '20M',
  'compress' => true,
  'copytruncate' => true,
  'missingok' => true,
  'delaycompress' => true,
  'notifempty' => true,

  '/var/log/wtmp' => {
    'missingok'   => true,
    'monthly'     => true,
    'create'      => '0664 root utmp',
    'rotate'      => 1
  },

  '/var/log/btmp' => {
    'missingok'   => true,
    'monthly'     => true,
    'create'      => '0660 root utmp',
    'rotate'      => 1
  }
}

include_recipe "logrotate::global"
