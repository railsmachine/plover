require 'spec_helper'

describe Plover::Servers do

  it "should create a plover servers object when given a connection and server specs hash" do
    servers = Plover::Servers.new([{:image_id => 1, :flavor_id => "m1.small"}])
    servers.class.should == Plover::Servers
  end

  describe 'provisioning' do
    describe "with customized security groups" do
      before :each do
        Fog::AWS::EC2.expects(:new).with(:aws_access_key_id => 'user', :aws_secret_access_key => 'key', :region => 'us-east-1').returns(true)
        Plover::Connection.establish_connection('aws_access_key_id' => 'user', 'aws_secret_access_key' => 'key', 'groups' => %w(default ssh))
        @servers = Plover::Servers.new([
          {:name => 'foo1', :image_id => 1, :flavor_id => "m1.small", :group => 'app'},
          {:name => 'foo2', :image_id => 1, :flavor_id => "m1.small", :groups => %w(riak)}
        ])
        stub_fog(:state => "terminated")
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
        @servers = Plover::Servers.new([
          {:image_id => 1, :flavor_id => "m1.small"},
          {:image_id => 1, :flavor_id => "m1.small"}
        ])
        stub_fog(:state => "terminated")
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
  end

end