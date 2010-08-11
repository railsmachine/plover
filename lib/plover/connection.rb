module Plover
  
  class Connection
    
    attr_accessor :connection
    
    def initialize(id, key)
      @connection = Fog::AWS::EC2.new(:aws_access_key_id => id, :aws_secret_access_key => key)
    end
    
    def provision_servers(server_specs)
      servers = Plover::Servers.new(self, server_specs)
      servers.provision
    end
    
    def shutdown_servers
      servers = Plover::Servers.new(self)
      servers.shutdown
    end
    
    def servers
      @connection.servers
    end
    
    def running_servers
      servers = Plover::Servers.new(self)
      servers.server_list.each do |server|
        puts "Server #{server.server_id} is #{server.state} at #{server.dns_name} for #{server.role}"
      end
    end
    
    def server_list
      servers = Plover::Servers.new(self)
      servers.server_list
    end
    
  end

end