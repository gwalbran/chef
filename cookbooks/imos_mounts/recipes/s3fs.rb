#
# Cookbook Name:: imos_mounts
# Recipe:: s3fs
#
if node[:lsb]['codename'].include?("precise")
  include_recipe "s3fs-fuse::install"
else
  package 's3fs'
end

# Override the original cookbook with our new template so we can specify access
# keys from a data bag
begin
  r = resources(:template => "/etc/passwd-s3fs")
  r.cookbook "imos_mounts"
rescue Chef::Exceptions::ResourceNotFound
  Chef::Log.warn "imos_mounts::s3fs could not find template to override!"
end
