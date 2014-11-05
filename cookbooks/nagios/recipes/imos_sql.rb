#
# Cookbook Name:: nagios
# Recipe:: imos_sql
#
# Copyright 2013, Example Company, Inc.
#
# This recipe defines the necessary NRPE commands for base system monitoring
# in Example Company Inc's Chef environment.
#

# Load nagios sql credentials from data bags
# Username
node.set['nagios']['server']['sql_username'] =
  Chef::EncryptedDataBagItem.load("passwords", "nagios_sql")['username']
# Password
node.set['nagios']['server']['sql_password'] =
  Chef::EncryptedDataBagItem.load("passwords", "nagios_sql")['password']

