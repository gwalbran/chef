require 'chefspec'

# Require all our *.rb files and libraries
Dir[::File.join(File.dirname(__FILE__), '..', 'files', 'default', '*.rb')].each { |f| require File.expand_path(f) }
Dir[::File.join(File.dirname(__FILE__), '..', 'libraries', '*.rb')].each { |f| require File.expand_path(f) }
