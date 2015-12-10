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
    begin
      return Nokogiri::XML(File.open(xml_file))
    rescue
      return nil
    end
  end

  # Returns value specified at given xpath, for example '/global/settings/proxyBaseUrl'
  def self.get_xml_value(xml_file, xpath)
    require 'nokogiri'
    xml_object = load_xml_file(xml_file) or return nil
    xpath_object = xml_object.at_xpath(xpath)
    xpath_object ? xpath_object.inner_html : nil
  end

  # insert/updates xml node at 'xpath' with 'value'
  def self.insert_xml_node(xml_file, xpath, value)
    require 'nokogiri'
    xml = load_xml_file(xml_file)
    if xml.nil?
      xml = Nokogiri::XML("")
    end
    xml_node = xml.at_xpath(xpath)

    # If our xpath is /1/2/3, iterate on path and add nodes as we go and
    # add/verify exists:
    # /1
    # /1/2
    # /1/2/3
    current_xpath = ""
    xpath.split("/")[1..-1].each do |elem|
      elem_xpath = current_xpath + "/" + elem

      xml_node = xml.at_xpath(elem_xpath)
      if ! xml_node
        new_node = Nokogiri::XML::Node.new(elem, xml)
        if current_xpath.empty?
          xml.add_child(new_node)
        else
          xml.at_xpath(current_xpath).add_child(new_node)
        end
      end
      current_xpath = elem_xpath
    end

    # Finally set the node text to the value passed to the function
    xml.at_xpath(xpath).inner_html = value.to_s

    # Write out the xml again
    File.open(xml_file, "w") do |data|
      data << xml
    end
  end

end
