#
# Cookbook Name:: imos_po
# Library:: data_services
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#

class Chef::Recipe::CronjobSanitizer

  def initialize(allowed_users = [], mocked = false)
    @allowed_users = allowed_users
    @mocked = mocked
  end

  def chef_header()
    return "# This file is managed by Chef, do not modify it by hand\n#\n\n"
  end

  def sanitize_cronjob_file(cronjob_in, cronjob_out, prefix, cron_vars)
    file_in = File.new(cronjob_in,  "r")

    file_out_buffer = ""

    begin
      while (line = file_in.gets)
        cronjob_line = sanitize_cronjob_line(line, prefix)
        if cronjob_line
          begin
            file_out_buffer += cronjob_line + "\n"
          end
        end
      end

      file_out = File.new(cronjob_out, "w")
      file_out.write(chef_header())
      file_out.write(cron_vars.collect { |k, v| "#{k}='#{v}'" }.join("\n") + "\n")
      file_out.write file_out_buffer
      file_out.close
    rescue
      Chef::Log.warn("Could not handle cronjob file '#{cronjob_in}'")
    end

    file_in.close
  end

  def get_user_for_cronjob(suggested_user)
    if @allowed_users.include?(suggested_user)
      return suggested_user
    else
      Chef::Log.warn "Not installing cronjob for unauthorized user '#{suggested_user}'"
      throw "Not installing cronjob for unauthorized user '#{suggested_user}'"
    end
  end

  def sanitize_cronjob_line(cronjob_string, prefix)
    # Strip trailing white spaces
    cronjob_string = cronjob_string.lstrip

    # Parse MAILTO and mock it out if needed (vagrant)
    if cronjob_string.start_with?("MAILTO=")
      if @mocked
        return "# MOCKED OUT " + cronjob_string.chomp
      else
        return cronjob_string.chomp
      end
    end

    # Use comments as is
    # Use SHELL=/bin/bash as is
    # Leave empty lines as is
    if cronjob_string.start_with?("#") ||
       cronjob_string.start_with?("SHELL=/bin/bash") ||
       cronjob_string == ""
      return cronjob_string.chomp
    end

    cronjob_parts = cronjob_string.split(/\s+/)

    # validate user is allowed to run the cronjob or use the default user
    # (usually nobody)
    cronjob_parts[5] = get_user_for_cronjob(cronjob_parts[5])

    # Append known prefix to command
    if cronjob_parts[6]
      cronjob_parts[6] = File.join(prefix, cronjob_parts[6])
    else
      return ""
    end

    # This is the command, again!
    # Make sure it exists!
    if ! File.exists?(cronjob_parts[6])
      Chef::Log.warn("Command '#{cronjob_parts[6]}' does not exist, cronjob will not be installed!")
      return ""
    end

    mocked_prefix = @mocked ? "# MOCKED " : ""
    return mocked_prefix + cronjob_parts.join(" ")
  end
end
