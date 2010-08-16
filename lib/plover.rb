require 'fog'

here = File.expand_path('.', File.dirname(__FILE__))
unless $LOAD_PATH.any? {|path| File.expand_path(path) == here }
  $LOAD_PATH.unshift(here)
end

require 'lib/plover/connection'
require 'lib/plover/servers'
require 'lib/plover/server'