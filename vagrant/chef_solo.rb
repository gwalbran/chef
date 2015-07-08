require 'json'
require 'fileutils'

def configure_chef_solo_provisioning(config, node_name, node_file_name, chef_log_level)

  vagrant_json = JSON.parse(File.open(node_file_name).read)


  config.vm.provision :chef_solo do |chef|

    chef.log_level = chef_log_level

    chef.roles_path = "roles"
    chef.data_bags_path = "data_bags"
    chef.provisioning_path = "/tmp/vagrant-chef"

    # Copy nodes into data_bags directory - when running in Vagrant mode,
    # chef-solo will look for nodes in data_bags/node/*, however in knife solo
    # mode nodes should be in nodes/*
    FileUtils.mkdir_p('data_bags/node')
    Dir['nodes/*'].each{ |f| FileUtils.cp(f,"data_bags/node") }

    # Use apt-cache if specified
    if ENV['VAGRANT_APT_CACHER']
      vagrant_json['run_list'].unshift 'recipe[apt::cacher-client]'
      vagrant_json['apt'] = { 'cacher_ipaddress' => ENV['VAGRANT_APT_CACHER'] }
    end

    # Inject Chef::Config[:dev] attribute by imos_core::dev recipe
    vagrant_json['run_list'].unshift('recipe[imos_core::dev]')

    chef.json = vagrant_json

    vagrant_json['run_list'].each do |item|
      chef.add_role(item) if item.start_with?("role[")
      chef.add_recipe(item) if item.start_with?("recipe[")
    end if vagrant_json['run_list']


    if vagrant_json['hostname']
      # Set chef node_name properly from node definition
      chef.node_name = "vagrant-#{vagrant_json['hostname']}"
    elsif vagrant_json['name']
      puts "WARNING: No node hostname found, using name instead!!!"
      chef.node_name = "vagrant-#{vagrant_json['name']}"
    else
      abort("Node has no name or hostname")
    end

  end
end
