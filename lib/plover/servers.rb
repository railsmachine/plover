module Plover
  
  class Servers
    
    def initialize(server_specs = {})
      @server_specs ||= server_specs
      if server_specs.empty?
        @servers = load_server_info.collect {|specs| Plover::Server.new(cspecs)}
      else
        @servers = server_specs.collect {|specs| Plover::Server.new(specs)}
      end
    end
    
    def provision
      @servers.each do |server|
        server.boot
        puts "Requested bootup for #{server.name}"
      end
      @servers.each do |server|
        server.update_once_running
        puts "Server #{server.name} is running as #{server.server_id}"
      end
      save_server_info
    end
    
    def shutdown
      @servers.each do |server|
        response = server.shutdown
        puts "Server #{server.server_id} shutdown" if response
      end
    end
    
    def server_list
      @servers
    end
    
    private
    
    def load_server_info
      plover_servers_yml_path = file_root().join("config", "plover_servers.yml")
      if plover_servers_yml_path.exist?
        YAML::load(plover_servers_yml_path.read)
      else
        {}
      end
    end
    
    def save_server_info
      File.open(file_root().join('config/plover_servers.yml'), 'w') do |out|
        out.write(yaml_output(@servers))
      end
    end

    def yaml_output(servers)
      server_array = servers.collect do |server|
        {:server_id => server.server_id, :dns_name => server.dns_name, :role => server.role, :name => server.name, :internal_ip => server.internal_ip}
      end
      server_array.to_yaml
    end
    
    def file_root
      Pathname.new(ENV['RAILS_ROOT'] || Dir.pwd)
    end
    
  end
  
end