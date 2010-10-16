module Plover

  class Server

    class ImmediatelyTerminatedError < StandardError; end

    attr_accessor :server_id, :name, :state, :dns_name, :role, :name, :external_ip, :internal_ip, :flavor_id, :image_id, :groups, :group, :reason, :options, :availability_zone

    def initialize(server_specs)
      @specs = server_specs
      set_attributes(@specs)
    end

    def boot
      begin
        unless state == 'running' || state == 'booting'
          @state = 'booting'
          @booting_server = Plover.connection.servers.create(:flavor_id => flavor_id, :image_id => image_id, :groups => groups, :user_data => cloud_config, :availability_zone => availability_zone)
          @server_id = @booting_server.id
          true
        end
      rescue Exception => e
        @state = 'exception'
        raise e
      end
    end

    def groups
      server_groups = (@groups || [])
      server_groups << @group if @group
      (Plover::Connection.groups + server_groups)
    end

    def booting?
      state == 'booting' && cloud_server.nil?
    end

    def running?
      cloud_server.state == "running" unless cloud_server.nil?
    end

    def availability_zone
      @availability_zone || (Plover::Connection.region + 'a')
    end

    def state
      @state || (cloud_server.nil? ? 'not found' : cloud_server.state)
    end

    def shutdown
      cloud_server.destroy
      update_from_running
    end

    def update_once_running
      if @booting_server
        begin
          @booting_server.wait_for do
            ready? || (raise Plover::Server::ImmediatelyTerminatedError if state == 'terminated')
          end
        rescue Plover::Server::ImmediatelyTerminatedError
          @state = 'terminated'
        else
          @state = 'running'
        end
      else
        @state = nil
      end
      update_from_running
    end

    alias_method :reload, :update_once_running

    def update_from_running
      if cloud_server
        set_attributes({
          :server_id          => cloud_server.id,
          :dns_name           => cloud_server.dns_name,
          :external_ip        => cloud_server.ip_address,
          :internal_ip        => cloud_server.private_ip_address,
          :state              => cloud_server.state,
          :reason             => cloud_server.reason
        })
      end
    end

    def cloud_config
      b = binding
      @cloud_config = ERB.new(Plover.cloud_config_path)
      @cloud_config.result(b)
    end

    def to_hash
      {
        :server_id          => server_id,
        :flavor_id          => flavor_id,
        :image_id           => image_id,
        :dns_name           => dns_name,
        :role               => role,
        :name               => name,
        :external_ip        => external_ip,
        :internal_ip        => internal_ip,
        :state              => state,
        :reason             => reason,
        :options            => options,
        :availability_zone  => availability_zone
      }
    end

    def to_s
      "Server #{name} is #{state} as #{server_id}"
    end

    private

    def set_attributes(server_hash)
      server_hash.each do |spec, value|
        send(spec.to_s+"=", value)
      end
    end

    def cloud_server
      Plover.connection.servers.get(server_id)
    end

  end

end