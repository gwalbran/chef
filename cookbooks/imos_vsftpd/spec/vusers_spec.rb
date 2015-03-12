require_relative 'spec_helper'

describe 'imos_vsftpd::vusers' do
  let (:chef_run) do
    ChefSpec::Runner.new do |node|
      node.automatic['imos_vsftpd']['local_root'] = "/ftp"
      node.automatic['imos_vsftpd']['ftp_users']['data_bags'] = [ "ftp_users/*" ]
    end.converge(described_recipe)
  end

  before do
    stub_search(:ftp_users, 'id:*').and_return([
      JSON.parse(File.read('test/fixtures/data_bags/ftp_users/ftp_users.json'))
    ])
  end

  it 'should define vuser links' do
    expect(chef_run).to create_directory("/etc/vsftpd/vusers")

    expect(chef_run).to create_link('/etc/vsftpd/vusers/test_1').with(to: '/etc/vsftpd/test_dir1')
    expect(chef_run).to create_link('/etc/vsftpd/vusers/test_2').with(to: '/etc/vsftpd/test_dir2')
  end

  it 'should define vuser mapping file' do
    expect(chef_run).to create_template('/etc/vsftpd/test_dir1').with(
      source: 'virtual_users_config.erb',
      owner: 'root',
      group: 'root',
      mode: 00644,
      variables: {
        :local_root => chef_run.node['imos_vsftpd']['local_root'],
        :mapping => 'test_dir1'
      }
    )

    expect(chef_run).to create_template('/etc/vsftpd/test_dir2').with(
      source: 'virtual_users_config.erb',
      owner: 'root',
      group: 'root',
      mode: 00644,
      variables: {
        :local_root => chef_run.node['imos_vsftpd']['local_root'],
        :mapping => 'test_dir2'
      }
    )
  end

  it 'should create vuser directories' do
    expect(chef_run).to create_directory("/ftp/test_dir1")
    expect(chef_run).to create_directory("/ftp/test_dir2")
  end


  it 'should create vsftpd password file' do
    pwdfile_content = "test_1:test_password_1\ntest_2:test_password_2\n"
    expect(chef_run).to create_file('/etc/vsftpd_pwdfile').with(
      content: pwdfile_content,
      owner: 'root',
      group: 'root',
      mode: 00600
    )
  end
end
