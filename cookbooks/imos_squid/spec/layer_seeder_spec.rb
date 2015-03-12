require_relative 'spec_helper'

describe 'imos_squid::layer_seeder' do
  let (:chef_run) do
    ChefSpec::Runner.new do |node|
      node.automatic.merge!(JSON.parse(File.read('test/fixtures/nodes/seeding-node.json')))
    end.converge(described_recipe)
  end

  it 'should install cronjob' do
    expect(chef_run).to create_cron('layer_seeder').with(
      command: "timeout 10m /usr/local/bin/geoserver_seeder.rb -P -u geonetwork-test -g geoserver-test -p 8080 -s 4 -e 10 -t 16 -T 256 -G 20 -U 'url-format-test\\%\\%' > /var/log/squid/layer_seeder.log 2>&1"
    )
  end

end
