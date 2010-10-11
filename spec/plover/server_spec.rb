require 'spec_helper'

describe Plover::Server do
  before :each do
    Fog::AWS::Compute::Mock.reset_data
    Plover::Connection.establish_connection('aws_access_key_id' => 'user', 'aws_secret_access_key' => 'key')
  end

  it "should raise an error when missing server specs" do
    lambda {
      Plover::Server.new
    }.should raise_error(ArgumentError)
  end

  it "should create a plover server instance when given server specs" do
    server = Plover::Server.new({:image_id => 1, :flavor_id => "m1.small"})
    server.class.should == Plover::Server
  end
  
  [:server_id, :name, :state, :dns_name, :role, :name, :external_ip, :internal_ip, :flavor_id, :image_id, :group, :reason, :options, :availability_zone].each do |setting|
    it "should set #{setting} from the specs hash on instantiation" do
      server = Plover::Server.new({setting => "test"})
      server.send(setting).should == "test"
    end
  end

  describe "with a valid connection " do
    before :each do
      @server = Plover::Server.new({:name => "abc", :image_id => "ami-12345"})
      @server.boot
      @server.reload
    end
    describe "when running" do
      it ".running? should return true" do
        @server.should be_running
      end
      it "should not start an instance if one is started" do
        Plover.connection.expects(:run_instances).never
        @server.boot.should_not be_true
      end
      it "should return the server state when asked for it" do
        @server.state.should == "running"
      end
      it "should be able to be shut down" do
        @server.shutdown
        @server.state.should == "shutting-down"
      end
    end
    describe "when terminated" do
      before :each do
        @server.shutdown
      end
      it ".running? should return false" do
        @server.should_not be_running
      end
      it ".boot should start an instance if one isn't started" do
        @server.boot.should be_true
        @server.state.should == "booting"
      end
      it "should return the server state when asked for it" do
        @server.state.should == "shutting-down"
      end
    end

  end
end