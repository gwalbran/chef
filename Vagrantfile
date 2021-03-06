# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'enumerator'

require_relative 'vagrant/plugins'
require_relative 'vagrant/chef_solo'
require_relative 'vagrant/virtualbox'

Vagrant.configure("2") do |config|

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
    config.cache.auto_detect = false
    config.cache.enable :apt
    config.cache.enable :gem
  end

  config.vm.box = ENV['VAGRANT_BOX'] || "xenial-server-amd64-chef-12.4.3-0.6"
  config.vm.box_url = ENV['VAGRANT_BOX_URL'] || "https://s3-ap-southeast-2.amazonaws.com/imos-binary/jobs/chef_basebox_virtualbox/20/xenial-server-amd64-chef-12.4.3-0.6.box"

  ENV['CHEF_VERSION'] and config.omnibus.chef_version = ENV['CHEF_VERSION']

  # ssh options
  config.ssh.username = ENV['VAGRANT_USER'] || "vagrant"
  config.ssh.forward_agent = true

  if ENV['VAGRANT_STATIC_IP']
    config.vm.network :private_network, ip: ENV['VAGRANT_STATIC_IP']
  else
    config.vm.network :private_network, type: "dhcp"
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

  config.vm.provision "shell", inline: "test `find /var/cache -maxdepth 1 -name apt -mtime -1 | wc -l` -eq 0 && sudo apt-get update; true"
  # Fix Ubuntu not booting after a failed boot
  config.vm.provision "shell", inline: "grep -q ^GRUB_RECORDFAIL_TIMEOUT /etc/default/grub || (echo GRUB_RECORDFAIL_TIMEOUT=3 | sudo tee -a /etc/default/grub && sudo update-grub)"

  define_node = Proc.new do |node_name|
    config.vm.define node_name, autostart: false do |node|
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
