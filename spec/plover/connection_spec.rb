require 'spec_helper'

describe Plover::Connection do

  it "should raise an error when accessing connection before establishing" do
    lambda {
      Plover.connection
    }.should raise_error(Plover::Connection::NotConnected)
  end

  it "should raise an error when missing a username and api key" do
    lambda {
      Plover::Connection.establish_connection
    }.should raise_error(ArgumentError)
  end

  it "should be able to connect from the yaml file" do
    Fog::AWS::EC2.expects(:new).with(:aws_access_key_id => 'user', :aws_secret_access_key => 'key', :region => 'us-east-1').returns(true)
    Plover::Connection.establish_connection_with_config_file("config/plover.yml")
  end

  it "should create an ec2 connection when given a proper username and api key" do
    Fog::AWS::EC2.expects(:new).with(:aws_access_key_id => 'user', :aws_secret_access_key => 'key', :region => 'us-east-1').returns(true)
    Plover::Connection.establish_connection('aws_access_key_id' => 'user', 'aws_secret_access_key' => 'key')
  end

  it "can connect to another region" do
    Fog::AWS::EC2.expects(:new).with(:aws_access_key_id => 'user', :aws_secret_access_key => 'key', :region => 'us-west-1').returns(true)
    Plover::Connection.establish_connection('aws_access_key_id' => 'user', 'aws_secret_access_key' => 'key', 'region' => 'us-west-1')
  end

  describe "with a connection" do
    before do
      Fog::AWS::EC2.stubs(:new).returns(true)
    end
    
    describe ".provision_servers" do
      it "should instanciate Plover::Servers and call provision" do
        servers = mock()
        Plover::Servers.expects(:new).returns(servers)
        servers.expects(:provision)
        Plover::Connection.provision_servers
      end
    end

    describe ".shutdown_servers" do
      it "should instanciate Plover::Servers and call shutdown" do
        servers = mock()
        Plover::Servers.expects(:new).returns(servers)
        servers.expects(:shutdown)
        Plover::Connection.shutdown_servers
      end
    end

  end
  
end
