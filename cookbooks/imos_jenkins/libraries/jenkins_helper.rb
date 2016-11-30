#
# Cookbook Name:: imos_jenkins
# Library:: jenkins_helper
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#

require 'openssl'
require 'net/ssh'

class Chef::Recipe::JenkinsHelper

  def self.get_key_pair
    ssh_private_key = Chef::EncryptedDataBagItem.load("users", "chef")['ssh_private_key']
    key = OpenSSL::PKey::RSA.new(ssh_private_key)
    private_key = key.to_pem
    public_key = "#{key.ssh_type} #{[key.to_blob].pack('m0')}"
    return { :private_key => private_key, :public_key => public_key }
  end

  def self.set_jenkins_creds(node)
    # Set the private key on the Jenkins executor
    private_key = get_key_pair()[:private_key]
    node.run_state[:jenkins_private_key] = private_key
  end

  def self.authenticate(node)
    set_jenkins_creds node
  end
end
