here = File.expand_path('.', File.dirname(__FILE__))
unless $LOAD_PATH.any? {|path| File.expand_path(path) == here }
  $LOAD_PATH.unshift(here)
end

require 'erb'
require 'yaml'
require 'pathname'
module Plover

  extend self

  autoload :Files,      'plover/files'
  autoload :Connection, 'plover/connection'
  autoload :Servers,    'plover/servers'
  autoload :Server,     'plover/server'

  def connection
    Connection.connection
  end

  def file_root
    Pathname.new(@file_root || Dir.pwd)
  end

  def file_root=(path)
    @file_root=path
  end

  def cloud_config_path
    @cloud_config_path || file_root.join('config', 'cloud-config.txt')
  end

  def cloud_config_path=(path)
    @cloud_config_path=path
  end

  def plover_config_path
    @plover_config_path || file_root.join('config', 'plover.yml')
  end

  def plover_config_path=(path)
    @plover_config_path=path
  end

  def plover_servers_config_path
    @plover_servers_config_path || file_root.join('config', 'plover_servers.yml')
  end

  def plover_servers_config_path=(path)
    @plover_servers_config_path=path
  end

end