module Plover

  class Server

    attr_accessor :server_id, :name, :state, :dns_name, :role, :name, :external_ip, :internal_ip, :flavor_id, :image_id, :groups, :group

    def initialize(server_specs)
      @specs = server_specs
      set_attributes(@specs)
    end

    def boot
      begin
        unless state == 'running' || state == 'booting'
          @state = 'booting'
          @booting_server = Plover.connection.servers.create(:flavor_id => flavor_id, :image_id => image_id, :groups => groups, :user_data => cloud_config)
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

    def state
      @state || (cloud_server.nil? ? 'not found' : cloud_server.state)
    end

    def shutdown
      cloud_server.destroy
    end

    def update_once_running
      @booting_server.wait_for { ready? } if @booting_server
      @state = 'running'
      update_from_running
    end

    def update_from_running
      if cloud_server
        hash = cloud_server.to_hash
        hash.delete(:role)
        hash.delete(:name)
        set_attributes(hash)
      end
    end

    def cloud_config
      b = binding
      @cloud_config = ERB.new(File.read("config/cloud-config.txt"))
      @cloud_config.result(b)
    end

    def to_hash
      {
        :server_id   => server_id,
        :flavor_id   => flavor_id,
        :image_id    => image_id,
        :dns_name    => dns_name,
        :role        => role,
        :name        => name,
        :external_ip => external_ip,
        :internal_ip => internal_ip,
        :state       => state
      }
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