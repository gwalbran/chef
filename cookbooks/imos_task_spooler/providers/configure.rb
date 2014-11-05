#
# Cookbook Name:: imos_task_spooler
# resource:: configure
#
# Copyright (C) 2014 IMOS
#
# All rights reserved - Do Not Redistribute
#

attr_reader :max_jobs
attr_reader :user
attr_reader :tsp

def load_current_resource
  @user          = new_resource.user
  @max_jobs      = new_resource.max_jobs
  @tsp           = node['imos_task_spooler']['command']
end

action :max_jobs do

  if %x{ which #{tsp} }
    current_configured_jobs = %x{ su - #{user} -c "#{tsp} -S" }

    if current_configured_jobs != max_jobs
      Chef::Log.info("Configuring task spooler with '#{max_jobs}' for user '#{user}'")
      %x{ su - #{user} -c "#{tsp} -S #{max_jobs}" }
      new_resource.updated_by_last_action(true)
    end

  else
    Chef::Application.fatal!("Task spooler is not installed, cannot configure for user '#{user}'")
  end

end
