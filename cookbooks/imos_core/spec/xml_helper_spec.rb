require_relative 'spec_helper'

SAMPLE_XML =
"""<?xml version=\"1.0\"?>
  <root>
    <node1>text1</node1>
    <node2>text2</node2>
    <node3>
      <node4>text4</node4>
    </node2>
  </root>
"""

describe Chef::Recipe::XMLHelper do
  describe 'insert_xml_node' do
    xml_file = nil

    before(:each) do
      xml_file = Tempfile.new('xml_file').path
      fd = File.open(xml_file, "w")
      fd.write(SAMPLE_XML)
      fd.close()
    end

    after(:each) do
      FileUtils::rm_f(xml_file)
    end

    it 'when file doesn not exist' do
      FileUtils::rm_f(xml_file)

      Chef::Recipe::XMLHelper.insert_xml_node(xml_file, "/root/node1", "1text")
      Chef::Recipe::XMLHelper.insert_xml_node(xml_file, "/root/node3/node4", "4text")

      xml = Nokogiri::XML(File.open(xml_file))

      expect("1text").to eq(xml.at_xpath("/root/node1").inner_html)
      expect("4text").to eq(xml.at_xpath("/root/node3/node4").inner_html)
    end

    it 'when node does not exist' do
      Chef::Recipe::XMLHelper.insert_xml_node(xml_file, "/root/node5", "text5")

      xml = Nokogiri::XML(File.open(xml_file))

      expect("text1").to eq(xml.at_xpath("/root/node1").inner_html)
      expect("text2").to eq(xml.at_xpath("/root/node2").inner_html)
      expect("text4").to eq(xml.at_xpath("/root/node3/node4").inner_html)
      expect("text5").to eq(xml.at_xpath("/root/node5").inner_html)
    end

    it 'when node exists' do
      Chef::Recipe::XMLHelper.insert_xml_node(xml_file, "/root/node1", "1text")
      Chef::Recipe::XMLHelper.insert_xml_node(xml_file, "/root/node2", "2text")
      Chef::Recipe::XMLHelper.insert_xml_node(xml_file, "/root/node3/node4", "4text")

      xml = Nokogiri::XML(File.open(xml_file))

      expect("1text").to eq(xml.at_xpath("/root/node1").inner_html)
      expect("2text").to eq(xml.at_xpath("/root/node2").inner_html)
      expect("4text").to eq(xml.at_xpath("/root/node3/node4").inner_html)
    end
  end
end
