#
# Cookbook Name:: talend
# Library:: job_helper
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#

class Talend
  class JobHelper
    # Static functions for paths in the talend hierarchy

    def self.job_dir(resource)
      ::File.join(resource.jobs_dir, resource.name)
    end

    def self.job_bin_dir(resource)
      ::File.join(job_dir(resource), "bin")
    end

    def self.job_java_dir(resource)
      ::File.join(job_dir(resource), "java")
    end

    def self.job_log_dir(resource)
      ::File.join(job_dir(resource), "log")
    end

    def self.job_conf_dir(resource)
      ::File.join(job_dir(resource), "etc")
    end

    def self.job_conf_file(resource)
      ::File.join(job_conf_dir(resource), "#{resource.name}.conf")
    end

    # Get the path to the installed linux job execution script
    def self.job_script_path(resource)
      base_dir = job_java_dir(resource)
      Dir[::File.join(base_dir, "**/*_run.sh")][0]
    end

    def self.get_run_job_file(resource)
      ::File.join(resource.bin_dir, "run_job.sh")
    end

    # Get the command to be executed by a trigger
    def self.job_command(resource)
      "#{get_run_job_file(resource)} -c #{job_conf_file(resource)} -l #{job_log_dir(resource)} -e #{job_script_path(resource)}"
    end

    # Get the command to be executed by a trigger
    def self.job_command_single_file(resource)
      "#{job_script_path(resource)} --context_param paramFile=\"#{job_conf_file(resource)}\" --context_param base=%{base} --context_param fileList=%{file_list} --context_param logDir=%{log_dir}"
    end

    def self.get_job_parameters(resource, node)
      job_parameters = {}

      # Add common parameters
      node['talend']['common_parameters'].each do |key, value|
        job_parameters[key] = value
      end

      # Specific parameters
      resource.params.each do |key, value|
        job_parameters[key] = value
      end

      # On mocked machines, run through the mock_filter function, preventing
      # talend jobs from hitting production resources
      if Chef::Config[:dev]
        mocked_job_parameters = {}
        job_parameters.each do |key, value|
          mocked_job_parameters[key] = mock_filter(key, value, node)
        end
        job_parameters = mocked_job_parameters
      end

      return job_parameters
    end

    def self.build_trigger_config(run_context, node)
      trigger_config = []

      # Iterate on all talend jobs and create triggers
      run_context.resource_collection.each do |resource|
        if resource.is_a?(Chef::Resource::TalendJob) &&
             resource.action.include?(:schedule) &&
             ! resource.trigger['event'].empty?
          job_parameters = get_job_parameters(resource, node)
          trigger_config << {
            'name'  => resource.name,
            'exec'  => job_command_single_file(resource),
            'regex' => resource.trigger['event']['regex']
          }
        end
      end

      return trigger_config
    end

    private

    # Return mocked config value if needs mocking, or original if not
    def self.mock_filter(config_item, config_value, node)
      node['talend']['mocked_config_regexps'].each do |mocked_config_regexp, mocked_value|
        if config_item.match /^#{mocked_config_regexp}$/
          return mocked_value
        end
      end

      return config_value
    end

  end
end
