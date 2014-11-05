#
# Cookbook Name:: tomcat
# Recipe:: default
#
# Copyright 2013, IMOS
#
# All rights reserved - Do Not Redistribute
#

#
# When running chef-solo, assumes that the data bag will be unencrypted.
#
class Chef::EncryptedDataBagItem

  def self.mock_data_bag(data_bag, name)
    if "ssl" == data_bag && ! name.end_with?('_insecure')
      mocked_name = "#{name}_insecure"
      Chef::Log.info "Redirecting data bag '#{data_bag}/#{name}' -> #{data_bag}/#{mocked_name}'"
      return mocked_name
    else
      return name
    end
  end

  def self.load(data_bag, name, secret = nil)

    Chef::Log.debug "Loading data bag (#{data_bag}, #{name})..."

    if Chef::Config[:vagrant]
      mocked_data_bag_name = self.mock_data_bag(data_bag, name)
      data_bag_content = Chef::DataBagItem.load(data_bag, mocked_data_bag_name)
      # Preseve id of data bag
      data_bag_content['id'] = name
      return data_bag_content
    elsif Chef::Config[:solo]
      return Chef::DataBagItem.load(data_bag, name)
    else
      raw_hash = Chef::DataBagItem.load(data_bag, name)
      secret = secret || self.load_secret
      self.new(raw_hash, secret)
    end
  end
end
