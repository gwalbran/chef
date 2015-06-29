#
# Cookbook Name:: imos_po
# Provider:: incoming_email
#
# Copyright (C) 2015 IMOS
#
# All rights reserved - Do Not Redistribute
#

action :add do
  write_conf
end

protected
  #
  # Walk collection for :add imos_po_incoming_email resources
  # Build and write authorized_keys
  #
  def write_conf
    incoming_email_aliases_path = node['imos_po']['email_aliases']

    content = incoming_email_aliases_content.join("\n") + "\n"
    f = file(incoming_email_aliases_path) do
      owner   'root'
      group   'root'
      mode    00644
      content content
    end

    execute "generate-incoming-email-aliases" do
      command "newaliases -oA#{incoming_email_aliases_path}"
    end

    new_resource.updated_by_last_action(f.updated?)
  end

  # The list of imos_po_incoming_email user resources in the resource collection
  #
  # @return [Array<Chef::Resource>]
  def imos_po_incoming_email
    run_context.resource_collection.select do |resource|
      resource.is_a?(Chef::Resource::ImosPoIncomingEmail)
    end
  end

  # Builds aliases content based on the list of imos_po_incoming_email users
  # defined in the resource collection
  #
  # @return [Array<String>]
  def incoming_email_aliases_content
    content = []
    imos_po_incoming_email.reduce({}) do |hash, resource|
      content << "#{resource.send('user')}: #{resource.send('email')}"
    end
    content
  end
