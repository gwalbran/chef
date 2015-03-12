require 'chefspec'
require 'chefspec/berkshelf'
require 'fileutils'

RSpec.configure do |config|
  config.before(:each) do
    FileUtils.cd File.join(File.dirname(__FILE__), '../')
  end
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end
