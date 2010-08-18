here = File.expand_path('.', File.dirname(__FILE__))
unless $LOAD_PATH.any? {|path| File.expand_path(path) == here }
  $LOAD_PATH.unshift(here)
end

require 'plover/files'
require 'plover/connection'
require 'plover/servers'
require 'plover/server'