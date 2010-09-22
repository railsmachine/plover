module Plover

  class Servers

    def self.file_root
      Pathname.new(ENV['RAILS_ROOT'] || Dir.pwd)
    end

    def initialize(server_specs = [])
      @server_specs ||= server_specs
      if server_specs.empty?
        @servers = load_server_info.collect {|specs| Plover::Server.new(specs)}
      else
        servers = server_specs.collect {|specs| Plover::Server.new(specs)}
        @servers = merge_running_config(servers)
      end
    end

    def merge_running_config(servers)
      running_config = load_server_info
      servers.map do |server|
        if running_server_config = running_config.find { |running_server| server.name == running_server[:name] }
          server.server_id = running_server_config[:server_id]
          server.update_from_running
        end
        server
      end
    end

    def provision
      @servers.each do |server|
        begin
          server.boot
        ensure
          save_server_info
        end
        puts "Requested bootup for #{server.name}"
      end
      @servers.each do |server|
        begin
          server.update_once_running
        ensure
          save_server_info
        end
        puts "Server #{server.name} is running as #{server.server_id}"
      end
    end

    def shutdown
      @servers.each do |server|
        response = server.shutdown
        save_server_info
        puts "Server #{server.server_id} shutdown" if response
      end
    end

    def server_list
      @servers
    end

    private

    def load_server_info
      plover_servers_yml_path = self.class.file_root.join("config", "plover_servers.yml")
      if File.exist?(plover_servers_yml_path)
        YAML::load_file(plover_servers_yml_path)
      else
        []
      end
    end

    def save_server_info
      yml = server_list.map(&:to_hash).to_yaml
      File.open(self.class.file_root.join('config/plover_servers.yml'), 'w') { |f| f.write(yml) }
    end

  end

end