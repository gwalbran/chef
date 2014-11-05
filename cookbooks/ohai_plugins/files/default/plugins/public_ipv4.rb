#
# Author:: Dan Fruehauf (<dan.fruehauf@utas.edu.au>)
# Copyright:: Copyright (c) 2013 IMOS, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

provides 'public_ipv4'

require 'net/http'
require 'json'

# Probe the main IP address of this machine
def get_main_ipaddress()
  # This means "get the IP address I'll use to get to 1.1.1.1"
  # 1.1.1.1 can be virtually anything on the internet
  main_ipaddress = `/sbin/ip route get 1.1.1.1`.split("\n").first

  # Do some string parsing required...
  # Run '/sbin/ip route get 1.1.1.1' to understand what's required
  if main_ipaddress
    main_ipaddress = main_ipaddress.split(/\s+/)[6].match(/\d+\.\d+\.\d+.\d+/).to_s
  end
  return main_ipaddress
end

# This function gets an IP address and returns true if it's a real internet
# address or false if it's a private address
def is_private_ip_address?(ip_address)
  # If the prefix of the IP address given matches any of the 'reserved'
  # subnets we listed above - it's a private address
  ip_address.start_with?("10.", "127.", "172.16.", "192.168.", "224.")
end

# Main provider for ohai attribute
begin
  # Machine IP address
  main_ipaddress = get_main_ipaddress()
  Ohai::Log.info("Probed machine IP address to be '#{main_ipaddress}'")

  # If main_ipaddress is either undefined, or is private, we should probe for
  # the public IP address via the internet
  if main_ipaddress.nil? || main_ipaddress.empty? || is_private_ip_address?(main_ipaddress)
    Ohai::Log.info("IP address '#{main_ipaddress}' is private")
    Ohai::Log.info("Initiating public IP address probing via HTTP")
    http = Net::HTTP.new("ifconfig.me")
    # If we pretend to be curl, we'll just get the string with the IP address
    req = Net::HTTP::Get.new("/", {'User-Agent' => 'curl 7.19.7 (x86_64-redhat-linux-gnu) libcurl/7.19.7 NSS/3.13.1.0 zlib/1.2.3 libidn/1.18 libssh2/1.2.2'})
    response = http.request(req)
    internet_address = response.body.match(/\d+\.\d+\.\d+.\d+/).to_s

    if internet_address
      network[:public_ipv4] = internet_address
    end
  else
    # So the machine has a public IP address on its interface - just use it
      Ohai::Log.info("IP address '#{main_ipaddress}' is public")
      network[:public_ipv4] = main_ipaddress
  end
end
