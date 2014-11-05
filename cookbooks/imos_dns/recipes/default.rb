#
# Cookbook Name:: imos_dns
# Recipe:: default
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

# A note about dns data bags:
# Since we can't have an ID of for a data bag with dots, we replace them
# with underscores, hence the calls to gsub("_", ".") and gsub(".", "_")
# It's a bit confusing, but not that.

include_recipe "imos_dns::route53"

