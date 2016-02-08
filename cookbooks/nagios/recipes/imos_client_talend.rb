#
# Cookbook Name:: nagios
# Recipe:: imos_client_talend
#
# Copyright 2013, IMOS
#
# This recipe defines all the NRPE monitors for talend monitoring
#

# Check all IMOS talend jobs defined on node
if node.recipe?("talend") && node['talend'] && node['talend']['jobs']
  node['talend']['jobs'].each do |job_name|
    # DF: TODO all of this logic should probably be implemented in the talend
    # cookbook, and we should call something like Talend::GetLogFileForJob()
    talend_job_data_bag = Chef::DataBagItem.load("talend", job_name)
    job_id = talend_job_data_bag['id']
    if job_id && ! talend_job_data_bag.has_key?('event')
      talend_console_log_file = ::File.join(node['talend']['jobs_dir'], "#{job_name}-#{job_id}", 'log', 'console.log')
      # nrpe check per job
      nagios_nrpecheck "check_talend_#{job_name}" do
        command "#{node['nagios']['plugin_dir']}/check_talend -n #{job_name} -c #{talend_console_log_file}"
        action :add
      end
    end
  end
end

