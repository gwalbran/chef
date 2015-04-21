require 'chefspec'

# Require all our libraries
Dir[::File.join(File.dirname(__FILE__), '..', 'libraries', '*.rb')].each { |f| require File.expand_path(f) }
