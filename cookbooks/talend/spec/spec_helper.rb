require 'chefspec'

# Require all our *.rb files
Dir[::File.join(File.dirname(__FILE__), '..', 'files', 'default', '*.rb')].each { |f| require File.expand_path(f) }
