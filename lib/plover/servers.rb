module Plover

  class Servers

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
      request_bootup
      request_info
    end


    def request_bootup
      @servers.each do |server|
        begin
          server.boot
          puts server.to_s
        ensure
          save_server_info
        end
      end
    end

    def request_info
      @servers.each do |server|
        begin
          server.update_once_running
          puts server.to_s
        ensure
          save_server_info
        end
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
      if File.exist?(Plover.plover_servers_config_path)
        YAML::load_file(Plover.plover_servers_config_path)
      else
        []
      end
    end

    def save_server_info
      yml = server_list.map(&:to_hash).to_yaml
      File.open(Plover.plover_servers_config_path, 'w') { |f| f.write(yml) }
    end

  end

end