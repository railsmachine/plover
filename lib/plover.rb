here = File.expand_path('.', File.dirname(__FILE__))
unless $LOAD_PATH.any? {|path| File.expand_path(path) == here }
  $LOAD_PATH.unshift(here)
end

module Plover
  require 'erb'
  
  autoload :Files,      'plover/files'
  autoload :Connection, 'plover/connection'
  autoload :Servers,    'plover/servers'
  autoload :Server,     'plover/server'

  def self.connection
    Connection.connection
  end

end