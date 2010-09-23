require 'rubygems'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

require 'plover'
require 'fakefs/safe'
require 'fog'
require 'mocha/standalone'

Spec::Runner.configure do |config|
  config.mock_with :mocha
  files = {}
  Dir["#{File.dirname(__FILE__)}/config/*"].each do |file|
    files[file] = File.read(file)
  end
  FakeFS.activate!
  Fog.mock!
  files.each do |name, contents|
    stripped_name = name.gsub("#{File.dirname(__FILE__)}\/", '')
    File.open(stripped_name, 'w') { |f| f.write(contents) }
  end
end