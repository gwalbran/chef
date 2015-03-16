#
# Cookbook Name:: talend
# Library:: postgresql_helper
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#

class Talend
  class PostgresqlHelper
    def self.get_role_password(databag_name, databag_id, role_name)
      return Chef::EncryptedDataBagItem.load(databag_name, databag_id)['roles'].
        select { |r| r['name'] == role_name }.first['password']
    end
  end
end
