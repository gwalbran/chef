#
# Cookbook Name:: imos_devel
# Recipe:: nco_devel
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

%w{
  debhelper
  antlr
  bison
  flex
  gsl-bin
  libgsl0-dev
  libantlr-dev
  netcdf-bin
  libnetcdf-dev
  libcurl4-gnutls-dev
  texinfo
  libudunits2-0
  libudunits2-dev
}.each do |package|
  package package
end
