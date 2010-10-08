require 'fog'

module Plover
  
  class Connection

    class NotConnected < StandardError; end

    class << self

      attr_reader :config, :region

      def establish_connection(hash = nil)
        @config = hash || YAML.load(ERB.new(File.read(Plover.plover_config_path)).result)
        @connection = Fog::AWS::Compute.new(:aws_access_key_id => @config['aws_access_key_id'], :aws_secret_access_key => @config['aws_secret_access_key'], :region => region)
      end

      def region
        config['region'] || 'us-east-1'
      end

      def groups
        config['groups'] || ['default']
      end

      def connection
        raise NotConnected if @connection.nil?
        @connection
      end

      def provision_servers
        servers = Plover::Servers.new(config["servers"])
        servers.provision
      end
    
      def shutdown_servers
        servers = Plover::Servers.new
        servers.shutdown
      end
    
      def servers
        @connection.servers
      end
    
      def running_servers
        servers = Plover::Servers.new
        servers.server_list.each do |server|
          puts "Server #{server.server_id} is #{server.state} at #{server.dns_name} for #{server.role}"
        end
      end
    
      def server_list
        servers = Plover::Servers.new
        servers.server_list
      end

    end
  end

end