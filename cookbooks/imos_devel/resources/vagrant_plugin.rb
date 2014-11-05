#
# Cookbook Name:: imos_devel
# resource:: vagrant_plugin
#
# Copyright (C) 2014 IMOS
#
# All rights reserved - Do Not Redistribute
#

actions        :install
default_action :install

# config attributes
attribute :user,    :kind_of => String, :required => true
attribute :home,    :kind_of => String, :required => true
attribute :version, :kind_of => String, :required => false
