#
# Cookbook Name:: nagios
# Recipe:: imos_client_input
#
# Copyright 2015, IMOS
#
# This recipe defines all the NRPE monitors for input processing
#

if node.recipe?("imos_po::data_services")
  # Include all of that in a ruby block, so we can run after the data-services
  # git repository was updated
  ruby_block "monitor_input_processing" do
    block do
      node['imos_po']['data_services']['monitored_watch_jobs'].each do |job|
        error_dir = ::File.join(node['imos_po']['data_services']['error_dir'], job)

        f = Chef::Resource::NagiosNrpecheck.new("check_input_error_#{job}", run_context)
        f.command "#{node['nagios']['plugin_dir']}/check_file_count -r -c 1 -w 1 -d #{error_dir}"
        f.run_action :add

        # This will also run before git[data_services] was updated for some
        # reason, so just guard against it...
        job_descriptor_path = ::File.join(node['imos_po']['data_services']['dir'], "watch.d", "#{job}.json")
        if ::File.exist?(job_descriptor_path)
          job_descriptor = JSON.parse(::File.read(job_descriptor_path))
          incoming_dir = ::File.join(node['imos_po']['data_services']['incoming_dir'], job_descriptor['path'][0])

          files_warn = job_descriptor['files_warn'] || 5
          files_crit = job_descriptor['files_crit'] || 10

          f = Chef::Resource::NagiosNrpecheck.new("check_input_incoming_#{job}", run_context)
          f.command "#{node['nagios']['plugin_dir']}/check_file_count -r -c #{files_crit} -w #{files_warn} -d #{incoming_dir}"
          f.run_action :add
        end
      end
    end
    subscribes :create, 'git[data_services]', :immediately
  end
end
