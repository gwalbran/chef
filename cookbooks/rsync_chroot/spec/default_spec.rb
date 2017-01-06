require 'spec_helper'
 
describe 'rsync_chroot::default' do
  let (:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }

  it 'should include the rsync package' do
    expect(chef_run).to install_package 'rsync'
  end
end
