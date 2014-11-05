#
# Cookbook Name:: imos_po
# Recipe:: packages
#
# Copyright (C) 2013 IMOS
#
# All rights reserved - Do Not Redistribute
#
# Sets up a server to allow project officers to do data manipulation

%w{antlr libantlr-dev libcurl4-gnutls-dev bison flex gcc g++ gsl-bin libgsl0-dev libnetcdf6 libnetcdf-dev netcdf-bin udunits-bin libudunits2-0 libudunits2-dev make}.each do |pkg|
  package pkg
end
