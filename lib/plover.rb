here = File.expand_path('.', File.dirname(__FILE__))
unless $LOAD_PATH.any? {|path| File.expand_path(path) == here }
  $LOAD_PATH.unshift(here)
end

require 'erb'
require 'yaml'
module Plover

  autoload :Files,      'plover/files'
  autoload :Connection, 'plover/connection'
  autoload :Servers,    'plover/servers'
  autoload :Server,     'plover/server'

  def self.connection
    Connection.connection
  end

end