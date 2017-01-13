require "chef/search/query"

class UsersQueryHelper
  def self.find_users_in_groups(groups)
    users_search_term = ""
    groups.each do |group|
      users_search_term += "groups:#{group} OR "
    end

    # remove trailing ' OR '
    users_search_term = users_search_term[0..-4]
    users_search_term += " NOT action:remove"

    begin
      return Chef::Search::Query.new.search(:users, users_search_term)
    rescue Net::HTTPServerException
      err_msg = 'Could not find appropriate items in the "users" databag.  Check to make sure there is a users databag and if you have set the "users_databag_groups" that users in that group exist'
      Chef::Log.fatal(errMsg)
      raise errMsg
    end
  end
end
