#
# Cookbook Name:: imos_core
# Library:: xml_helper
#
# Copyright 2014, IMOS
#
# All rights reserved - Do Not Redistribute
#

class Chef::Recipe::XMLHelper
  # "Defensive" loading of chef gem nokogiri, as describe in:
  # https://github.com/opscode-cookbooks/aws/blob/master/libraries/ec2.rb#L43-L47
  begin
    require 'nokogiri'
  rescue LoadError
    Chef::Log.warn("Missing gem 'nokogiri'. Use imos_core::xml_helper recipe to install it first.")
  end

  # Simply loads an XML file with Nokogiri
  def self.load_xml_file(xml_file)
    require 'nokogiri'
    Nokogiri::XML(File.open(xml_file))
  end

  # Returns value specified at given xpath, for example '/global/settings/proxyBaseUrl'
  def self.get_xml_value(xml_file, xpath)
    require 'nokogiri'
    xpath_object = load_xml_file(xml_file).at_xpath(xpath)
    xpath_object ? xpath_object.inner_html : nil
  end

  # insert/updates xml node named 'name' at 'xpath' with 'value'
  def self.insert_xml_node(xml_file, xpath, name, value)
    require 'nokogiri'
    @xml = load_xml_file(xml_file)
    xml_node = @xml.at_xpath("#{xpath}/#{name}")

    if xml_node
      # Node already exists, lets edit it
      xml_node.inner_html = value
    else
      # Need to add a new node
      new_node = Nokogiri::XML::Node.new name, @xml
      new_node.content = value
      # Using File.dirname to strip the last element
      @xml.at_xpath(xpath).children.last.add_next_sibling(new_node)
    end

    # Write out the xml again
    File.open(xml_file, "w") do |data|
      data << @xml
    end
  end

end
