require 'spec_helper'

describe Plover::Servers do

  it "should create a plover servers object when given a connection and server specs hash" do
    servers = Plover::Servers.new([{:image_id => 1, :flavor_id => "m1.small"}])
    servers.class.should == Plover::Servers
  end

  describe 'provisioning' do
    describe "with customized security groups" do
      before :each do
        Fog::AWS::EC2.expects(:new).with(:aws_access_key_id => 'user', :aws_secret_access_key => 'key').returns(true)
        Plover::Connection.establish_connection('aws_access_key_id' => 'user', 'aws_secret_access_key' => 'key', 'groups' => %w(default ssh))
        @servers = Plover::Servers.new([
          {:image_id => 1, :flavor_id => "m1.small", :group => 'app'},
          {:image_id => 1, :flavor_id => "m1.small", :groups => %w(riak)}
        ])
        stub_fog(:state => "terminated")
      end
      it ".boot? should start an instance in the appropriate security groups" do
        @servers.server_list.each do |server|
          server.expects(:update_once_running)
        end
        Plover::Connection.connection.servers.expects(:create).with(:flavor_id => "m1.small", :image_id => 1, :groups => ["default", "ssh", "riak"], :user_data => File.read("config/cloud-config.txt"))
        Plover::Connection.connection.servers.expects(:create).with(:flavor_id => "m1.small", :image_id => 1, :groups => ["default", "ssh", "app"], :user_data => File.read("config/cloud-config.txt"))
        @servers.provision
      end
    end

    describe "with default security groups" do
      before :each do
        Fog::AWS::EC2.expects(:new).with(:aws_access_key_id => 'user', :aws_secret_access_key => 'key').returns(true)
        Plover::Connection.establish_connection('aws_access_key_id' => 'user', 'aws_secret_access_key' => 'key')
        @servers = Plover::Servers.new([
          {:image_id => 1, :flavor_id => "m1.small"},
          {:image_id => 1, :flavor_id => "m1.small"}
        ])
        stub_fog(:state => "terminated")
      end
      it ".boot? should start an instance in the default security group" do
        @servers.server_list.each do |server|
          server.expects(:update_once_running)
        end
        Plover::Connection.connection.servers.expects(:create).with(:flavor_id => "m1.small", :image_id => 1, :groups => ["default"], :user_data => File.read("config/cloud-config.txt"))
        Plover::Connection.connection.servers.expects(:create).with(:flavor_id => "m1.small", :image_id => 1, :groups => ["default"], :user_data => File.read("config/cloud-config.txt"))
        @servers.provision
      end
    end
  end

end