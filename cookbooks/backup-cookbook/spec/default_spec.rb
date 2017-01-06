require 'spec_helper'

describe 'backup::default' do
  let (:chef_run) do
    ChefSpec::Runner.new do |node|
      node.automatic['backup']['packages'] = [ "package1", "package2" ]
    end.converge(described_recipe)
  end

  it 'should install packages default recipe' do
    expect(chef_run).to install_package("package1")
    expect(chef_run).to install_package("package2")
  end

  it 'should create user and group' do
    expect(chef_run).to create_user("backup")
  end

  it 'should create directories' do
    expect(chef_run).to create_directory("/home/backup")
    expect(chef_run).to create_directory("/home/backup/backup")
    expect(chef_run).to create_directory("/home/backup/models")
    expect(chef_run).to create_directory("/home/backup/bin")
    expect(chef_run).to create_directory("/var/log/backup")
  end
end
