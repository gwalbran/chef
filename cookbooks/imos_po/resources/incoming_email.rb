#
# Cookbook Name:: imos_po
# Resource:: incoming_email
#
# Copyright (C) 2015 IMOS
#
# All rights reserved - Do Not Redistribute
#

actions :add
default_action :add

attribute :user,  :kind_of => String, :name_attribute => true
attribute :email, :kind_of => String, :default  => nil
