require 'spec_helper'

describe 'imos_vsftpd::pam' do
  let (:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }

  before do
    stub_search(:ftp_users, 'id:*').and_return([
      JSON.parse(File.read('test/fixtures/data_bags/ftp_users/ftp_users.json')),
    ])
  end

  it 'should create vsftpd pam configuration' do
    expect(chef_run).to create_template('/etc/pam.d/pam_vsftpd').with(
      source: 'pam_vsftpd.erb',
      owner: 'root',
      group: 'root',
      mode: 00644
    )
  end
end
