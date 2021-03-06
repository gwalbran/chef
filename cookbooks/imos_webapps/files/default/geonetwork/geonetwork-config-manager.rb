#!/usr/bin/env ruby

require 'json'
require 'uri'
require 'net/http'
require 'net/https'
require 'trollop'
require 'open-uri'
require 'nokogiri'
require 'xmlsimple'
require 'logger'
require 'rexml/document'
require 'equivalent-xml'

$logger = Logger.new(STDOUT)
$logger.level = Logger::INFO

@config = nil
@prefix = 'srv/eng'
@logo_path = 'data/resources/images/harvesting'
@NULL_ENTITY_ID = -1

# Generates a HTTP POST request to GeoNetwork with provided credentials
#
# Params:
# * *Args* :
#   - +username+ -> GeoNetwork username for login credentials
#   - +password+ -> GeoNetwork password for login credentials
#   - +url+ -> GeoNetwork service URL for POST request
#   - +param_hash+ -> GeoNetwork service parameters for POST request in hash format
#
def http_post_request(username, password, url, param_hash)
  uri = URI.parse(url)
  req = Net::HTTP::Post.new(uri.request_uri)
  req.basic_auth(username, password)
  req.set_form_data(param_hash)

  res = Net::HTTP::start(uri.hostname, uri.port) do |http|
    http.request(req)
  end

  if not res.kind_of? Net::HTTPSuccess
    $logger.info "GeoNetwork http service #{url} failed with error code #{res.code} and stacktrace #{res.body}"
    exit 1
  end
end

# Generates a HTTP POST request with xml body to GeoNetwork with provided credentials
#
# Params:
# * *Args* :
#   - +username+ -> GeoNetwork username for login credentials
#   - +password+ -> GeoNetwork password for login credentials
#   - +url+ -> GeoNetwork service URL for POST request
#   - +xml_param+ -> XML representing structure for GeoNetwork harvester
#
def http_post_request_xml_body(username, password, url, xml_param)
  uri = URI.parse(url)
  req = Net::HTTP::Post.new(uri.request_uri)
  req.basic_auth(username, password)
  req.body = xml_param
  req.content_type = 'text/xml'

  res = Net::HTTP::start(uri.hostname, uri.port) do |http|
    http.request(req)
  end

  if not res.kind_of? Net::HTTPSuccess
    $logger.info "GeoNetwork http service with xml body #{url} failed with error code #{res.code} and stacktrace #{res.body}"
    exit 1
  end
end

# Checks to see if a GeoNetwork entity already exists in the defined instance
#
# Params:
# * *Args* :
#   - +username+ -> GeoNetwork username for login credentials
#   - +password+ -> GeoNetwork password for login credentials
#   - +url+ -> GeoNetwork service URL for POST request
#   - +entity_xpath+ -> xpath query to select the required GN entity 
#   - +id_element+ -> the entity id element to search for, i.e username
#   - +id+ -> the entity id value to search for, i.e user1
#   - +found_xpath+ -> xpath query to select the identifying value in the GN entity to return
# * *Returns* :
#   - id of the entity if entity exists, -1 otherwise
#
def entity_exists(username, password, url, entity_xpath, id_element, id, found_xpath)
  entity_id = @NULL_ENTITY_ID
  uri = URI.parse(url)
  req = Net::HTTP::Post.new(uri.request_uri)
  req.basic_auth(username, password)

  res = Net::HTTP::start(uri.hostname, uri.port) do |http|
    http.request(req)
  end

  if not res.kind_of? Net::HTTPSuccess
    $logger.info "GeoNetwork http service with #{url} failed with error code #{res.code} and stacktrace #{res.body}"
    exit 1
  end

  xml_doc = Nokogiri::XML(res.body)
  xml_doc.xpath(File.join(entity_xpath)).each do |entity|
    if id == entity.search(id_element).xpath('text()').to_s
      entity_id = entity.xpath(found_xpath).to_s
    end
  end

  return entity_id
end

# Add a new user to a GeoNetwork instance. Checks to see if user already exists.
# If so, update user info rather than add new user
#
# Params:
# * *Args* :
#   - +auth_username+ -> GeoNetwork username for login credentials
#   - +auth_password+ -> GeoNetwork password for login credentials
#   - +url+ -> GeoNetwork instance URL
#   - +param_hash+ -> List of user parameters in hash format
#
def add_user(auth_username, auth_password, url, param_hash)
  entity_id = entity_exists(
    auth_username, auth_password,
    File.join(url, @prefix, "xml.info?type=users"),
    "//info/users/user", "username", param_hash['username'],
    "id/text()")

  if entity_id.to_i > @NULL_ENTITY_ID
    param_hash[:id] = entity_id
    http_post_request(
      auth_username, auth_password,
      File.join(url, @prefix, "user.update?operation=editinfo"), param_hash)

    pw_reset_param = {
      'id' => entity_id,
      'username' => param_hash['username'],
      'password' => param_hash['password'],
      'profile' => param_hash['profile']}

    http_post_request(
      auth_username, auth_password,
      File.join(url, @prefix, "user.update?operation=resetpw"), pw_reset_param)
  else
    http_post_request(
      auth_username, auth_password,
      File.join(url, @prefix, "user.update?operation=newuser"), param_hash)
  end
end

# Adds a harvester to a GeoNetwork instance
#
# Params:
# * *Args* :
#   - +auth_username+ -> GeoNetwork username for login credentials
#   - +auth_password+ -> GeoNetwork password for login credentials
#   - +url+ -> GeoNetwork instance URL
#   - +xml_param+ -> harvester data in xml format for ingestion into GeoNetwork instance
#   - +harvester_name+ -> harvester name (unique id)
#
def add_harvester(auth_username, auth_password, url, xml_param, harvester_name)
  entity_id = entity_exists(
    auth_username, auth_password,
    File.join(url, @prefix, "xml.harvesting.get"),
    "//nodes/node", "name", harvester_name, "string(@id)")
  service = "xml.harvesting.add"

  if entity_id.to_i > @NULL_ENTITY_ID
    service = "xml.harvesting.update"
    xml_doc = Nokogiri::XML(xml_param)
    node = xml_doc.at_css "node"
    node['id'] = entity_id
    xml_param = xml_doc.to_s
  end

  http_post_request_xml_body(
    auth_username, auth_password,
    File.join(url, @prefix, service), xml_param)
end

# Get xml data from GeoNetwork for vocab files
#
# Params:
# * *Args* :
#   - +username+ -> GeoNetwork username for login credentials
#   - +password+ -> GeoNetwork password for login credentials
#   - +url+ -> GeoNetwork request url
#   - +param_hash+ -> List of request parameters in hash format. Optional
# * *Returns* :
#   - Nokogiri XML document containing response body. If failure, nil is returned
#
def get_xml_content(username, password, url, param_hash=nil)
  response = nil
  uri = URI.parse(url)
  req = Net::HTTP::Post.new(uri.request_uri)
  req.basic_auth(username, password)
  if param_hash
    req.set_form_data(param_hash)
  end

  res = Net::HTTP::start(uri.hostname, uri.port) do |http|
    http.request(req)
  end

  if not res.kind_of? Net::HTTPSuccess
    $logger.info "GeoNetwork http service with xml body #{url} failed with error code #{res.code} and stacktrace #{res.body}"
    exit 1
  end

  return Nokogiri::XML(res.body)
end

# Adds a logo to a GeoNetwork instance.
#
# * *Args* :
#   - +data_dir+ -> GeoNetwork data directory
#   - +url+ -> GeoNetwork instance URL
#   - +param_hash+ -> List of vocab parameters in hash format
#
def add_logo(data_dir, param_hash)
  download_link = param_hash['link']
  filename = param_hash['image']
  download = open(download_link)
  IO.copy_stream(download,
    File.join(data_dir, @logo_path, filename))
end

# Adds a vocabulary to a GeoNetwork instance.
# If vocab exists already, delete the existing vocab and upload
# Rebuild the lucene index after each upload
#
# Params:
# * *Args* :
#   - +auth_username+ -> GeoNetwork username for login credentials
#   - +auth_password+ -> GeoNetwork password for login credentials
#   - +url+ -> GeoNetwork instance URL
#   - +param_hash+ -> List of vocab parameters in hash format
# * *Returns* :
#   - True if vocab is not present, false if present
#
def add_vocab(auth_username, auth_password, url, param_hash)
  vocab_not_present = true
  vocab_content_to_add = Nokogiri::XML(open(param_hash['url']).read)
  xml_doc = get_xml_content(
    auth_username, auth_password,
    File.join(url, @prefix, "xml.thesaurus.getList"))

  if xml_doc
    xml_doc.xpath(File.join("//response/thesauri/thesaurus")).each do |vocab|
      vocab_key = vocab.xpath("key/text()").to_s
      download_param = {'ref' => vocab_key}
      xml_res = get_xml_content(
      auth_username, auth_password,
      File.join(url, @prefix, "thesaurus.download"), download_param)
      if xml_res
        if EquivalentXml.equivalent?(
            vocab_content_to_add, xml_res,
            opts = { :element_order => false, :normalize_whitespace => true })
          vocab_not_present = false
        elsif vocab_key == param_hash['key']
          # If the vocab files are not equivalent but the key already exists replace with the updated file
          delete_param = {'ref' => vocab_key}
          delete_vocab(auth_username, auth_password, url, delete_param)
        end
      end
    end
  end

  if vocab_not_present
    http_post_request(
      auth_username, auth_password,
      File.join(url, @prefix, "xml.thesaurus.upload"), param_hash)
  end

  return vocab_not_present
end

# Deletes a vocabulary from a GeoNetwork instance.
#
# Params:
# * *Args* :
#   - +auth_username+ -> GeoNetwork username for login credentials
#   - +auth_password+ -> GeoNetwork password for login credentials
#   - +url+ -> GeoNetwork instance URL
#   - +param_hash+ -> List of vocab parameters in hash format
#
def delete_vocab(auth_username, auth_password, url, param_hash)
  http_post_request(
    auth_username, auth_password,
    File.join(url, @prefix, "thesaurus.delete"), param_hash)
end

def manage_logos(data_dir)
  @config['logos'].each do |logo|
    add_logo(data_dir, logo)
  end if @config['logos']
end

def manage_users(url, username, password)
  @config['users'].each do |user|
    add_user(username, password, url, user)
  end if @config['users']
end

def manage_harvesters(url, username, password)
  @config['harvesters'].each do |harvester|
    xml_doc = REXML::Document.new XmlSimple.xml_out(harvester, 'AttrPrefix' => true,
      'ContentKey' => 'textContent', 'RootName' => 'node')
      xml_str = ""
      xml_doc.write(xml_str)
    add_harvester(username, password, url, xml_str, harvester['site']['name'])
  end if @config['harvesters']
end

def manage_vocabs(url, username, password)
  vocabs_added = 0
  present_vocabs = []
  vocabs_to_delete = []
  vocabs_to_configure = []

  if @config['vocabularies']
    vocab_xml = get_xml_content(
      username, password,
      File.join(url, @prefix, "xml.thesaurus.getList"))

    if vocab_xml
      vocab_xml.xpath(File.join("//response/thesauri/thesaurus")).each do |present_vocab|
        present_vocabs.push(present_vocab.xpath("key/text()").to_s)
      end
    end

    @config['vocabularies'].each do |vocabulary|
      vocabs_to_configure.push(vocabulary['key'])
    end

    vocabs_to_delete = present_vocabs - vocabs_to_configure

    vocabs_to_delete.each do |vocab_key|
      delete_param = {'ref' => vocab_key}
      delete_vocab(username, password, url, delete_param)
    end

    @config['vocabularies'].each do |vocab|
      if add_vocab(username, password, url, vocab)
        vocabs_added += 1
      end
    end

    if vocabs_added > 0
      rebuild_param = {'reset' => 'yes'}
      http_post_request(username, password,
        File.join(url, @prefix, "metadata.admin.index.rebuild"), rebuild_param)
    end
  end    
end

def manage_reindex(url, username, password, do_reindex)
  if do_reindex
    rebuild_param = {'reset' => 'yes'}
    http_post_request(username, password,
      File.join(url, @prefix, "metadata.admin.index.rebuild"), rebuild_param)
  end
end

def main(url, data_dir, username, password, do_reindex)
  manage_logos(data_dir)
  manage_harvesters(url, username, password)
  manage_vocabs(url, username, password)
  manage_reindex(url, username, password, do_reindex)
  manage_users(url, username, password)
end

if __FILE__ == $0
  # Arguments parsing
  opts = Trollop::options do
  banner <<-EOS
  Configure a Geonetwork instance with settings defined in external configuration

  Example:
    ./geonetwork-config-manager.rb -g "http://catalogue-123.aodn.org.au/geonetwork" -d "/mnt/ebs/geonetwork_portal" -c "geonetwork-config.json" -u "admin" -p "admin"

  Example config file:
  {
    "users": [
      {
        "email": "user1111@one.com",
        "kind": "gov",
        "name": "user",
        "password": "userone",
        "profile": "Administrator",
        "surname": "oneone",
        "username": "user1"
      },
      {
        "email": "user2222@one.com",
        "kind": "gov",
        "name": "user2",
        "password": "usertwo",
        "profile": "Administrator",
        "surname": "twotwo",
        "username": "user2"
      }
    ],
    "vocabularies": [
      {
        "key": "external.place.aodn_aodn-discovery-parameter-vocabulary_version-1-1",
        "url": "http://vocabs.ands.org.au/repository/api/download/165/aodn_aodn-discovery-parameter-vocabulary_version-1-1.rdf",
        "dir": "place",
        "type": "external",
        "mode": "file"
      }
    ]
  }

  Options:
  EOS
  opt :url, "Geonetwork URL",
    :type => :string,
    :short => '-g'
  opt :data_dir, "Geonetwork data directory",
    :type => :string,
    :short => '-d'
  opt :config, "Config file",
    :type => :string,
    :short => '-c'
  opt :username, "Geonetwork username",
    :type => :string,
    :short => '-u'
  opt :password, "Geonetwork password",
    :type => :string,
    :short => '-p'
  opt :reindex, "Geonetwork lucene reindex",
    :short => '-r'
  end

  Trollop::die :url, "Must specify Geonetwork URL" if ! opts[:url]
  Trollop::die :url, "Must specify Geonetwork data directory" if ! opts[:data_dir]
  Trollop::die :config, "Must specify configuration file" if ! opts[:config]
  Trollop::die :username, "Must specify Geonetwork username" if ! opts[:username]
  Trollop::die :password, "Must specify Geonetwork password" if ! opts[:password]

  config_file = opts[:config]
  begin
    @config = JSON.parse(File.read(config_file))
  rescue
    Trollop::die :config, "Could not read config file '#{config_file}'"
  end

  main(opts[:url], opts[:data_dir], opts[:username], opts[:password], opts[:reindex])
  exit(0)
end
