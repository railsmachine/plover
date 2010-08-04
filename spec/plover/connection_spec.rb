require 'spec_helper'

describe Plover::Connection do
  
  it "should raise an error when missing a username and api key" do
    lambda {
      Plover::Connection.new
    }.should raise_error(ArgumentError)
  end
  
  it "should create an ec2 connection when given a proper username and api key" do
    Fog::AWS::EC2.expects(:new).returns(true)
    Plover::Connection.new("user", "key")
  end
  
  describe "with a connection" do
    before do
      Fog::AWS::EC2.stubs(:new).returns(true)
      @plover = Plover::Connection.new("user", "key")
    end
    
    describe ".provision_servers" do
      it "should instanciate Plover::Servers and call provision" do
        servers = mock()
        Plover::Servers.expects(:new).returns(servers)
        servers.expects(:provision)
        @plover.provision_servers({:flavor => "m1.small"})
      end
    end

    describe ".shutdown_servers" do
      it "should instanciate Plover::Servers and call shutdown" do
        servers = mock()
        Plover::Servers.expects(:new).returns(servers)
        servers.expects(:shutdown)
        @plover.shutdown_servers()
      end
    end

  end
  
  
  
end