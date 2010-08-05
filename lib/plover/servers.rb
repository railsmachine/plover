module Plover
  
  class Servers
    
    def initialize(connection, server_specs = {})
      @server_specs ||= server_specs
      @connection = connection
    end
    
    def provision
      ec2_servers = @server_specs.collect do |specs|
        server = create_server(specs)
        server_properties(server, specs["role"], specs["name"])
      end
      save_server_info(ec2_servers)
    end
    
    def shutdown
      servers = load_server_info
      servers.each do |server|
        response = @connection.servers.get(server[:server_id]).destroy
        puts "Server #{server[:server_id]} shutdown" if response
      end
    end
    
    def running_servers
      servers = load_server_info
      servers.collect do |server|
        info = @connection.servers.get(server[:server_id])
        info.nil? ? next : {:id => info.id, :state => info.state, :dns => info.dns_name, :name => server[:name]}
      end
    end
    
    def running_server(name)
      running_servers.select {|server| server[:name] == name}.first
    end
    
    private
    
    def create_server(specs)
      if running_specs = running_server(specs["name"])
        puts "Server #{running_specs[:name]} is already running at #{running_specs[:dns]}."
        server = @connection.servers.get(running_specs[:id])
      else
        server = @connection.servers.create(:flavor_id => specs["flavor"], :image_id => specs["image"], :groups => ["default", "ssh"], :user_data => File.read("config/cloud-config.txt"))
        server.wait_for { ready? }
        puts "Server #{server.id} started at #{server.dns_name}"
        server
      end
    end
    
    def load_server_info
      plover_servers_yml_path = file_root().join("config", "plover_servers.yml")
      if plover_servers_yml_path.exist?
        YAML::load(plover_servers_yml_path.read)
      else
        {}
      end
    end
    
    def save_server_info(servers)
      File.open(file_root().join('config/plover_servers.yml'), 'w') do |out|
        out.write(servers.to_yaml)
      end
    end

    def server_properties(server, role, name)
      {:server_id => server.id, :dns_name => server.dns_name, :role => role, :name => name}
    end
    
    def file_root
      Pathname.new(ENV['RAILS_ROOT'] || Dir.pwd)
    end
    
  end
  
end