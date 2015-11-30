def configure_virtualbox_provider(config, node_name)
  config.vm.provider "virtualbox" do |v|

    v.name = node_name
    if ENV['VAGRANT_MEMORY']
      v.customize ['modifyvm', :id,'--memory', ENV['VAGRANT_MEMORY'] ]
    end

    if ENV['VAGRANT_CPUS']
      v.cpus = ENV['VAGRANT_CPUS']
    end

  end
end
