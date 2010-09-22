require 'spec_helper'

describe Plover::Server do
  
  it "should raise an error when missing server specs" do
    lambda {
      Plover::Server.new
    }.should raise_error(ArgumentError)
  end
  
  it "should create a plover server instance when given server specs" do
    server = Plover::Server.new({:image_id => 1, :flavor_id => "m1.small"})
    server.class.should == Plover::Server
  end
  
  it "should set attr_accessors from the specs hash on instantiation" do
    server = Plover::Server.new({:role => "app"})
    server.role.should == "app"
  end
  
  describe "with a valid connection " do
    describe "when running" do
      before :each do
        stub_fog(:state => "running")
      end
      it ".running? should return true" do
        server = Plover::Server.new({:name => "abc", :image_id => "ami-12345"})
        server.should be_running
      end
      it "should not start an instance if one is started" do
        Plover.connection.servers.expects(:create).never
        server = Plover::Server.new({:name => "abc", :image_id => "ami-12345"})
        server.boot.should be_false
      end
      it "should start an instance if one isn't started" do
        Plover.connection.servers.get.expects(:destroy)
        server = Plover::Server.new({:name => "abc", :image_id => "ami-12345"})
        server.shutdown
      end
      it "should return the server state when asked for it" do
        server = Plover::Server.new({:name => "abc", :image_id => "ami-12345"})
        server.state.should == "running"
      end
    end
    describe "when terminated" do
      before :each do
        stub_fog(:state => "terminated")
      end
      it ".running? should return false" do
        server = Plover::Server.new({:name => "abc", :image_id => "ami-12345"})
        server.should_not be_running
      end
      it ".boot should start an instance if one isn't started" do
        Plover.connection.servers.expects(:create)
        server = Plover::Server.new({:name => "abc", :image_id => "ami-12345"})
        server.boot.should be_true
      end
      it "should return the server state when asked for it" do
        server = Plover::Server.new({:name => "abc", :image_id => "ami-12345"})
        server.state.should == "terminated"
      end
    end

  end
end