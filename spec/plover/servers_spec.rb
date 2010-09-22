require 'spec_helper'

describe Plover::Servers do

  describe "when initializing a server list" do

    before :each do
      stub_fog(:state => "terminated", :to_hash => { :state => "terminated", :dns_name => 'test_terminated.cloud.com' })
      hash = [{:name => 'test_terminated', :server_id => 'foo', :state => 'running', :dns_name => "test_terminated.cloud.com"}]
      File.open(Plover::Servers.file_root.join('config', 'plover_servers.yml'), 'w') { |f| f.write(hash.to_yaml)}
      @servers = Plover::Servers.new([{:name => 'test_terminated', :role => 'test', :image_id => 1, :flavor_id => "m1.small"}])
    end

    it "should merge the provided with the running config" do
      @servers.server_list.first.dns_name.should == 'test_terminated.cloud.com'
    end

    it "should load the data from the cloud api to ensure freshness" do
      @servers.server_list.first.state.should == 'terminated'
    end
  end

  describe 'provisioning' do
    describe "with customized security groups" do
      before :each do
        Fog::AWS::EC2.expects(:new).with(:aws_access_key_id => 'user', :aws_secret_access_key => 'key', :region => 'us-east-1').returns(true)
        Plover::Connection.establish_connection('aws_access_key_id' => 'user', 'aws_secret_access_key' => 'key', 'groups' => %w(default ssh))
        stub_fog(:state => "terminated", :to_hash => {})
        @servers = Plover::Servers.new([
          {:name => 'foo1', :image_id => 1, :flavor_id => "m1.small", :group => 'app'},
          {:name => 'foo2', :image_id => 1, :flavor_id => "m1.small", :groups => %w(riak)}
        ])
      end
      it ".boot should start an instance in the appropriate security groups" do
        @servers.server_list.each do |server|
          server.expects(:update_once_running)
        end
        Plover.connection.servers.expects(:create).with(:flavor_id => "m1.small", :image_id => 1, :groups => ["default", "ssh", "riak"], :user_data => File.read("config/cloud-config.txt"))
        Plover.connection.servers.expects(:create).with(:flavor_id => "m1.small", :image_id => 1, :groups => ["default", "ssh", "app"], :user_data => File.read("config/cloud-config.txt"))
        @servers.provision
        server_output = YAML.load_file('config/plover_servers.yml')
        server_output.should_not be_empty
        server_output.each do |server|
          server[:name].should =~ /foo/
          server[:state].should == 'booting'
        end
      end

      it ".boot should write out server info as provisioning happens" do
        Plover.connection.servers.expects(:create).with(:flavor_id => "m1.small", :image_id => 1, :groups => ["default", "ssh", "app"], :user_data => File.read("config/cloud-config.txt"))
        Plover.connection.servers.expects(:create).with(:flavor_id => "m1.small", :image_id => 1, :groups => ["default", "ssh", "riak"], :user_data => File.read("config/cloud-config.txt")).raises(StandardError)
        lambda {
          @servers.provision
        }.should raise_error(StandardError)
        server_output = YAML.load_file('config/plover_servers.yml')
        server_output.should_not be_empty
        server_output.first[:state].should == 'booting'
        server_output.last[:state].should == 'exception'
      end
    end

    describe "with default security groups" do
      before :each do
        Fog::AWS::EC2.expects(:new).with(:aws_access_key_id => 'user', :aws_secret_access_key => 'key', :region => 'us-east-1').returns(true)
        Plover::Connection.establish_connection('aws_access_key_id' => 'user', 'aws_secret_access_key' => 'key')
        stub_fog(:state => "terminated", :to_hash => {})
        @servers = Plover::Servers.new([
          {:image_id => 1, :flavor_id => "m1.small"},
          {:image_id => 1, :flavor_id => "m1.small"}
        ])
      end
      it ".boot should start an instance in the default security group" do
        @servers.server_list.each do |server|
          server.expects(:update_once_running)
        end
        Plover.connection.servers.expects(:create).with(:flavor_id => "m1.small", :image_id => 1, :groups => ["default"], :user_data => File.read("config/cloud-config.txt"))
        Plover.connection.servers.expects(:create).with(:flavor_id => "m1.small", :image_id => 1, :groups => ["default"], :user_data => File.read("config/cloud-config.txt"))
        @servers.provision
      end
    end

    describe "when a server was last seen in a booting state, but has since started" do
      before :each do
        Fog::AWS::EC2.expects(:new).with(:aws_access_key_id => 'user', :aws_secret_access_key => 'key', :region => 'us-east-1').returns(true)
        Plover::Connection.establish_connection('aws_access_key_id' => 'user', 'aws_secret_access_key' => 'key')

        hash = [{:name => 'test_running', :server_id => 'foo', :state => 'running', :dns_name => "test_running.cloud.com"}]
        File.open(Plover::Servers.file_root.join('config', 'plover_servers.yml'), 'w') { |f| f.write(hash.to_yaml)}

        stub_fog(:state => "running", :to_hash => { :state => "running", :dns_name => 'test_running.cloud.com' })

        @servers = Plover::Servers.new([
          {:name => "test_running", :image_id => 1, :flavor_id => "m1.small"},
        ])

      end

      it "should detect server is running" do
        @servers.server_list.first.state.should == 'running'
      end

      it ".boot should not start duplicate instances" do
        Plover.connection.servers.expects(:create).never
        @servers.provision
      end

    end

  end

end