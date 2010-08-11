require 'spec_helper'

describe Plover::Server do
  
  it "should raise an error when missing a connection and server specs" do
    lambda {
      Plover::Server.new
    }.should raise_error(ArgumentError)
  end
  
  it "should create a plover server instance when given a connection and server specs" do
    server = Plover::Server.new("connection", {:image_id => 1, :flavor_id => "m1.small"})
    server.class.should == Plover::Server
  end
  
  it "should set attr_accessors from the specs hash on instanciation" do
    server = Plover::Server.new("connection", {:role => "app"})
    server.role.should == "app"
  end
  
  describe "with a valid connection " do
    def connection(response)
      stub_fog(response)
    end
    
    describe ".running?" do
      it "should return true when the server is running" do
        server = Plover::Server.new(connection(:state => "running"), {:name => "abc", :image_id => "ami-12345"})
        server.should be_running
      end
      
      it "should return false when the server is terminated" do
        server = Plover::Server.new(connection(:state => "terminated"), {:name => "abc", :image_id => "ami-12345"})
        server.should_not be_running
      end
    end
    
    describe ".boot" do
      it "should start an instance if one isn't started" do
        conn = connection(:state => "terminated")
        conn.servers.expects(:create)
        server = Plover::Server.new(conn, {:name => "abc", :image_id => "ami-12345"})
        server.boot.should be_true
      end
      
      it "should not start an instance if one is started" do
        conn = connection(:state => "running")
        conn.servers.expects(:create).never
        server = Plover::Server.new(conn, {:name => "abc", :image_id => "ami-12345"})
        server.boot.should be_false
      end
      
      it "should start an instance if the current one is terminated" do
        conn = connection(:state => "terminated")
        conn.servers.expects(:create)
        server = Plover::Server.new(conn, {:name => "abc", :image_id => "ami-12345"})
        server.boot.should be_true
      end
    end
    
    describe ".shutdown" do
      it "should start an instance if one isn't started" do
        conn = connection(:state => "running")
        conn.servers.get.expects(:destroy)
        server = Plover::Server.new(conn, {:name => "abc", :image_id => "ami-12345"})
        server.shutdown
      end
    end
    
    describe ".state" do
      it "should return the server state when asked for it" do
        server = Plover::Server.new(connection(:state => "running"), {:name => "abc", :image_id => "ami-12345"})
        server.state.should == "running"
      end
    end
  end
  
end