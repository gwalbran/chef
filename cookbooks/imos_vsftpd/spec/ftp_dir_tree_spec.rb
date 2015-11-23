require_relative 'spec_helper'

describe 'imos_vsftpd::ftp_dir_tree' do
  let (:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.automatic['imos_vsftpd']['ftp_dir_tree']['root'] = "/ftp"
      node.automatic['imos_vsftpd']['ftp_dir_tree']['data_bags'] = [ "ftp_dir_tree/*" ]
    end.converge(described_recipe)
  end

  before do
    stub_search(:ftp_users, 'id:*').and_return([
      JSON.parse(File.read('test/fixtures/data_bags/ftp_users/test_1.json')),
      JSON.parse(File.read('test/fixtures/data_bags/ftp_users/test_2.json'))
    ])

    stub_search(:ftp_dir_tree, 'id:*').and_return([
      JSON.parse(File.read('test/fixtures/data_bags/ftp_dir_tree/test1.json')),
      JSON.parse(File.read('test/fixtures/data_bags/ftp_dir_tree/test2.json'))
    ])
  end

  it 'should create dir tree' do
    expect(chef_run).to create_directory("/ftp/test1").with(
      owner: 'ftp',
      group: 'users',
      mode: '00755',
      recursive: true
    )

    expect(chef_run).to create_directory("/ftp/test1/test2").with(
      owner: 'ftp',
      group: 'users',
      mode: '02775',
      recursive: true
    )
  end
end
