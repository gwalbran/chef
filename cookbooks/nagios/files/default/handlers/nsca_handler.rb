
require 'rubygems'
require 'chef/log'
require 'chef'
require 'chef/config'

module Imos
  class NSCAHandler < Chef::Handler

    def initialize
    end

    def report
      @w_elapsed_time  = Chef::Config['elapsed_time_warning']       || run_status.node['nagios']['chef_client_warn_sec'] || 600
      @c_elapsed_time  = Chef::Config['elapsed_time_critical']      || run_status.node['nagios']['chef_client_crit_sec'] || 1200
      @c_updated_res   = Chef::Config['updated_resources_critical'] || run_status.node['nagios']['chef_client_crit_res'] || 500
      @w_updated_res   = Chef::Config['updated_resources_warning']  || run_status.node['nagios']['chef_client_warn_res'] || 300

      service_name   = run_status.node['nagios']['nsca']['chef_client_service_name'] || "chef-client"
      broadcast_nsca = run_status.node['nagios']['nsca']['broadcast_nsca']
      ret=''
      if run_status.failed? || (run_status.elapsed_time > @c_elapsed_time.to_i ) || (run_status.updated_resources.length > @c_updated_res.to_i)
        ret=2
        Chef::Log.info( "Setting host status critical:#{run_status.failed?} | #{run_status.elapsed_time} | #{@c_elapsed_time.to_i} | #{run_status.updated_resources.length} | #{@c_updated_res.to_i}")
      elsif (run_status.elapsed_time > @w_elapsed_time.to_i) || (run_status.updated_resources.length > @w_updated_res.to_i)
        Chef::Log.info( "Setting host status warning: #{run_status.elapsed_time} | #{@w_elapsed_time.to_i} | #{run_status.updated_resources.length}")
        ret=1
      else
        ret=0
      end
      host_name = Chef::Config['nagios_hostname'] || run_status.node[:fqdn]
      msg_string="#{host_name};#{service_name};#{ret};Start:#{run_status.start_time};Time:#{run_status.elapsed_time};Updated:#{run_status.updated_resources.length};All:#{run_status.all_resources.length}"
      Chef::Log.info("send_nsca msg_string : #{msg_string}")

      Chef::Log.info("echo \"#{msg_string}\" | #{broadcast_nsca} -d ';'")
      Chef::Log.info(`echo \"#{msg_string}\" | #{broadcast_nsca} -d ';'`)
    end
  end
end
