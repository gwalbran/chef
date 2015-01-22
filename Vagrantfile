# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'enumerator'

require_relative 'vagrant/chef_solo'
require_relative 'vagrant/virtualbox'

Vagrant.configure("2") do |config|

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
    config.cache.auto_detect = false
    config.cache.enable :apt
    config.cache.enable :gem
  end

  config.vm.box = ENV['VAGRANT_BOX'] || "precise64-chef-client-omnibus-11.4.0-0.4"
  config.vm.box_url = ENV['VAGRANT_BOX_URL'] || "https://binary.aodn.org.au/static/boxes/precise64-chef-client-omnibus-11.4.0-0.4.box"

  # ssh options
  config.ssh.username = ENV['VAGRANT_USER'] || "vagrant"
  config.ssh.forward_agent = true

  config.vm.network :private_network, type: "dhcp"

  if ENV['VAGRANT_STATIC_IP']
    config.vm.network :private_network, ip: ENV['VAGRANT_STATIC_IP']
  end

  node_file_path = ENV['VAGRANT_NODE_FILE_PATH'] || 'nodes'
  chef_log_level = ENV.fetch("CHEF_LOG", "info").downcase.to_sym

  node_file_extension = '.json'

  is_node_file = Proc.new do |f|
    f.end_with?(node_file_extension)
  end

  basename = Proc.new do |f|
    f.chomp(node_file_extension)
  end

  config.vm.provision "shell", inline: "sudo apt-get update"

  define_node = Proc.new do |node_name|
    config.vm.define node_name do |node|
      configure_virtualbox_provider node, node_name
      # Provision if node name was specified.
      configure_chef_solo_provisioning node, node_name, "#{node_file_path}/#{node_name}.json", chef_log_level
    end
  end

  Dir.entries(node_file_path).
    select(&is_node_file).
    collect(&basename).
    each(&define_node)

end
