require 'digest'
require 'yaml'
require 'fileutils'

attr_reader :job_common_name
attr_reader :job_name
attr_reader :job_dir
attr_reader :job_bin_dir
attr_reader :job_java_dir
attr_reader :job_log_dir
attr_reader :job_conf_dir
attr_reader :job_conf_file
attr_reader :job_parameters

# load current state

def load_current_resource
  @job_common_name = new_resource.common_name
  @job_name        = new_resource.name
  @job_dir         = ::File.join(new_resource.jobs_dir, @job_name)
  @job_bin_dir     = ::File.join(@job_dir, "bin")
  @job_java_dir    = ::File.join(@job_dir, "java")
  @job_log_dir     = ::File.join(@job_dir, "log")
  @job_conf_dir    = ::File.join(@job_dir, "etc")
  @job_conf_file   = ::File.join(@job_conf_dir, "#{@job_name}.conf")
  @job_parameters  = Talend::JobHelper.get_job_parameters(new_resource, node)
end

action :configure do

  [ job_bin_dir, job_log_dir, job_conf_dir ].each do |dir|
    ::FileUtils.mkdir_p(dir)
    ::FileUtils.chown(new_resource.process_owner, new_resource.process_group, dir)
    ::FileUtils.chmod(0755, dir)
  end

  # Evaluate parameters
  evaluated_job_parameters = {}
  @job_parameters.each do |key, value|
    if value.kind_of? String
      begin
        evaluated_job_parameters[key] = eval( %{"#{value}"} )
      rescue
        Chef::Log.warn("Talend '#{@job_name}' ignoring parameter '#{key}'")
      end
    end
  end

  # create job parameter file
  template job_conf_file do
    cookbook  "talend"
    source    "talend_config.erb"
    owner     new_resource.owner
    group     new_resource.group
    mode      0644
    variables ({
      :params    => evaluated_job_parameters,
      :delimiter => new_resource.delimiter
    })
  end

  # process harvester specific resources
  unless new_resource.harvest_resources.nil?

    # process directories that might need creating
    dirs = new_resource.harvest_resources['directories']
    unless dirs.nil?
      dirs.each do |dir|
        # substitute attributes
        dir = eval( %{"#{dir}"} )
        directory dir do
          recursive true
          owner     new_resource.process_owner
          group     new_resource.process_group
          mode      0755
        end
      end
    end

    # process harvester cookbook files
    files = new_resource.harvest_resources['files']
    unless files.nil?
      files.each do |src, dst|
        # substitute attributes
        dst = eval( %{"#{dst}"} )
        cookbook_file dst do
          source src
          owner  new_resource.owner
          group  new_resource.group
          mode   0644
        end
      end
    end

    # install harvester specific packages
    packages = new_resource.harvest_resources['packages']
    unless packages.nil?
      packages.each do |package_|
        package package_ do
          action :install
        end
      end
    end
  end

end

# deploy talend job
action :deploy do
  imos_artifacts_deploy job_name do
    install_dir                job_java_dir
    artifact_id                new_resource.artifact_id
    artifact_manifest          new_resource.artifact_manifest
    file_destination           ::File.join(job_dir, "#{new_resource.common_name}.zip")
    # Remove redundant directory structure
    remove_top_level_directory true
    owner                      'root'
    group                      'root'
  end
end

# Remove a talend job
action :remove do
  # Remove trigger for job (if there is one)
  Talend::JobHelper.remove_trigger(node['talend']['trigger']['config'], job_name)

  if Dir.exists?(job_dir)
    rubbish_dir = new_resource.rubbish_dir
    rubbish_dir_for_job = ::File.join(rubbish_dir, "#{job_name}-#{Time.now.strftime('%Y%m%d-%H%M%S')}")
    Chef::Log.info("Talend '#{job_name}' was abandoned, moving to '#{rubbish_dir_for_job}'")
    ::FileUtils.mv(job_dir, rubbish_dir_for_job)
  end
end

# Build wrapper script for job
action :schedule do
  # Change privileges of artifact job script
  ::FileUtils.chmod(00755, Talend::JobHelper.job_script_path(new_resource))
  ::FileUtils.chown(new_resource.owner, new_resource.group, Talend::JobHelper.job_script_path(new_resource))

  if new_resource.trigger['event'].empty?
    # Schedule using cron

    wrapper_script = ::File.join(job_bin_dir, "#{job_name}.sh")

    cron_command = "#{node['imos_task_spooler']['tsp_if_not_queued']} #{job_name} #{Talend::JobHelper.job_command(new_resource)}"

    file wrapper_script do
      owner   new_resource.process_owner
      group   new_resource.process_group
      mode    0755
      content "#!/bin/bash
#{cron_command}
"
    end

    cron job_name do
      minute  new_resource.trigger['cron']['minute']  || node['talend']['minute']
      hour    new_resource.trigger['cron']['hour']    || node['talend']['hour']
      day     new_resource.trigger['cron']['day']     || "*"
      month   new_resource.trigger['cron']['month']   || "*"
      weekday new_resource.trigger['cron']['weekday'] || "*"
      command wrapper_script
      user    new_resource.process_owner
      mailto  new_resource.mailto
      path    new_resource.path
      home    new_resource.home
      shell   new_resource.shell
    end

  else
    # Trigger a job based on pattern matching
    Talend::JobHelper.add_trigger(
      node['talend']['trigger']['config'],
      new_resource.name,
      Talend::JobHelper.job_command_single_file(new_resource),
      new_resource.trigger['event']['regex']
    )
  end

end
