require_relative 'spec_helper'

describe 'imos_vsftpd::default' do
  let (:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }

  before do
    stub_search(:ftp_users, 'id:*').and_return([
      JSON.parse(File.read('test/fixtures/data_bags/ftp_users/ftp_users.json')),
    ])
  end

  it 'should install vsftpd package' do
    expect(chef_run).to install_package("vsftpd")
  end

  it 'should install libpam-pwdfile package' do
    expect(chef_run).to install_package("libpam-pwdfile")
  end

  it 'should use template from imos_vsftpd cookbook' do
    expect(chef_run).to create_template('/etc/vsftpd.conf').with(
      source: 'vsftpd.conf.erb',
      cookbook: 'imos_vsftpd'
    )
  end
end
