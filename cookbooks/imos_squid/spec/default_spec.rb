require_relative 'spec_helper'

describe 'imos_squid::default' do
  let (:chef_run) do
    ChefSpec::Runner.new do |node|
      node.automatic.merge!(JSON.parse(File.read('test/fixtures/nodes/node.json')))
    end.converge(described_recipe)
  end

  it 'should install squid package' do
    expect(chef_run).to install_package('squid')
  end

  it 'should install squid.conf template from our cookbook' do
    expect(chef_run).to create_template('/etc/squid/squid.conf').with(
      source: 'squid.conf.erb',
      cookbook: 'imos_squid',
    )
  end

  it 'should parse node webapps' do
    expect(chef_run).to create_template('/etc/squid/squid.conf').with(
      variables: {
        :host_acl => [],
        :url_acl => [],
        :acls => [],
        :directives => [],
        :refresh_patterns => [],
        :custom_config => [
          "custom config line1",
          "custom config line2"
        ],
        :refresh_patterns => [
          {
            "regex" => "http://localhost:8080//regex1",
            "extra_opts" => "override-expire ignore-reload",
            "min" => 7200,
            "max" => 7200
          },
          {
            "regex" => "http://localhost:8080//regex2",
            "extra_opts" => "override-expire ignore-reload"
          },
          {
            "regex" => "http://localhost:8081//regex3",
            "extra_opts" => "override-expire ignore-reload",
            "min" => 2628000,
            "max" => 2628000
          }
        ]
      }
    )
  end
end
