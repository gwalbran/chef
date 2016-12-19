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
    require 'json'

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

    def self.get_cmdline_params(params)
      cmdline_params = []

      params.each do |key, value|
        cmdline_params << "--context_param #{key}=#{value}"
      end

      return cmdline_params.join(' ')
    end

    def self.get_trigger_events(events)
      trigger_events = []

      events.each do |event|
        trigger_event = {}
        trigger_event['regex'] = event['regex']

        if event['extra_params']
          trigger_event['extra_params'] = get_cmdline_params(event['extra_params'])
        end

        trigger_events << trigger_event
      end

      return trigger_events
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

    def self.get_triggers(trigger_file)
      config = json_as_hash_from_file(trigger_file)
      triggers = []
      triggers = config.collect { |k, v| k }
      return triggers
    end

    def self.add_trigger(trigger_file, name, exec, events)
      config = json_as_hash_from_file(trigger_file)

      config[name] = {
        'exec'  => exec,
        'events' => events
      }

      hash_as_json_to_file(trigger_file, config)
    end

    def self.remove_trigger(trigger_file, name)
      config = json_as_hash_from_file(trigger_file)

      if config[name]
        config.delete(name)
      end

      hash_as_json_to_file(trigger_file, config)
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

    def self.json_as_hash_from_file(file)
      retval = {}
      begin
        retval = JSON.parse(File.read(file))
      rescue
        Chef::Log.warn("Not a valid json file '#{file}'")
      end
      return retval
    end

    def self.hash_as_json_to_file(file, config)
      # Use a temp file to obtain atomicity for file modifications
      tmp_file = Tempfile.new(File.basename(file), File.dirname(file))
      tmp_file.write(JSON.pretty_generate(config, :indent => "    ") + "\n")
      tmp_file.close
      FileUtils.mv(tmp_file.path, file)
      FileUtils.chmod(00644, file)
    end

  end
end
