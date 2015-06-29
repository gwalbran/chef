#
# Cookbook Name:: imos_vsftpd
# Recipe:: vusers
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#

def generate_mapping_name(mapping)
  mapping_name = mapping.gsub('/', '_')
  if mapping_name[0] == '_'
    mapping_name = mapping_name[1..-1]
  end
  return mapping_name
end

directory '/etc/vsftpd/vusers' do
  owner     "root"
  group     "root"
  mode      0755
  recursive true
end

pwdfile_content = []

# Loop through users in ftp_user databag
node['imos_vsftpd']['ftp_users']['data_bags'].each do |data_bag_pattern|

  # break something like 'ftp_users/*' to 'vusers' and '*'
  # or something like 'ftp_users/ftp_users to 'ftp_users' and 'ftp_users
  data_bag_pattern_name     = File.dirname(data_bag_pattern)
  data_bag_pattern_wildcard = File.basename(data_bag_pattern)
  search("#{data_bag_pattern_name}", "id:#{data_bag_pattern_wildcard}").each do |data_bag|

    data_bag['ftp_users'].each do |user|

      Chef::Log.info("Creating ftp mapping '#{user['id']}' -> '#{user['mapping']}'")

      mapping_name = generate_mapping_name(user['mapping'])
      mapping_file = ::File.join("/etc/vsftpd", mapping_name)

      template mapping_file do
        source "virtual_users_config.erb"
        owner  "root"
        group  "root"
        mode   00644
        variables(
          :local_root => node[:imos_vsftpd][:local_root],
          :mapping    => user['mapping']
        )
      end

      # Create the staging directories, they must NOT be writeable by ftp - its a requirement of vsftpd
      directory ::File.join(node[:imos_vsftpd][:local_root], user['mapping']) do
        owner     "ftp"
        group     "users"
        mode      02575
        recursive true
      end

      # create the symlinks from the users to the chroot templates, this defines which users are locked to which directories
      link ::File.join("/etc/vsftpd/vusers", user['id']) do
        to mapping_file
      end

      Chef::Log.info("Creating password for ftp user '#{user['firstname']} #{user['lastname']}'")

      # Build the passwd file
      pwdfile_content << "#{user['id']}:#{user['password']}"

      # Add email alias for that user
      imos_po_incoming_email user['id'] do
        email user['email']
      end if user['email']
    end

  end
end

# Password file
file "/etc/vsftpd_pwdfile" do
  content pwdfile_content.join("\n") + "\n"
  owner   "root"
  group   "root"
  mode    00600
end
