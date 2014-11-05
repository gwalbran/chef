
class ImosDns
  def initialize
    require 'net/http'
    require 'net/https'
    require 'uri'
  end

  # Given a list of domains, returns the domain the hostname resides in
  # by stripping it's first part until no more parts are left and comparing
  # reursively with the list of domains we have
  # returns Nil if nothing found
  def split_fqdn(domains, fqdn)
    domain_iter = fqdn
    hostname = ""
    while domain_iter != ""
      domains.each do |domain|
        if domain == domain_iter
          # 0..-2 for stripping the last .
          return hostname[0..-2], domain_iter
        end
      end
      hostname += domain_iter.split(".")[0] + "."
      # Strip one piece of the hostname
      domain_iter = domain_iter.split(".")[1..-1].join(".")
    end
    return nil
  end
end

