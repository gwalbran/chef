#
# Cookbook Name:: jenkins
# Recipe:: s3_plugin_profile
#
# Copyright 2016, IMOS
#
# All rights reserved - Do Not Redistribute
#
# Recipe to define all slaves on a master
#

jenkins_user_data_bag = Chef::EncryptedDataBagItem.load("users", node['imos_jenkins']['user'])

jenkins_script 'create S3 profile' do
  command <<-EOH.gsub(/^ {4}/, '')
    import jenkins.model.*
    import hudson.plugins.s3.*

    def instance = Jenkins.getInstance()
    def desc = instance.getDescriptor("hudson.plugins.s3.S3BucketPublisher")

    def s3profile = new S3Profile(
      "S3Profile-jenkins",
      "#{jenkins_user_data_bag['access_key_id']}",
      "#{jenkins_user_data_bag['secret_access_key']}",
      false,
      5,
      "5",
      "5",
      "5",
      "5",
      false
    )

    instance.save()
  EOH
end
