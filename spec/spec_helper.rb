require 'rubygems'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

require 'plover'

Spec::Runner.configure do |config|
  config.mock_with :mocha
end

def stub_fog(response = {})
  servers = stub(:get => stub(response))
  connection = stub(:servers => servers)
end

