required = [ 'vagrant-berkshelf' ]

required.each do |plugin_name|
  # Adapted from http://zacharyflower.com/2014/09/22/how-to-force-installation-of-vagrant-plugins/
  unless Vagrant.has_plugin?(plugin_name)
    system("vagrant plugin install #{plugin_name}") &&
    raise("#{plugin_name} installed. Run command again.");
  end
end
