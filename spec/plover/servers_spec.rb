require 'spec_helper'

describe Plover::Servers do
  
  it "should raise an error when missing a connection" do
    lambda {
      Plover::Servers.new
    }.should raise_error(ArgumentError)
  end
  
  it "should create a plover servers object when given a connection and server specs hash" do
    servers = Plover::Servers.new("connection", [{:image_id => 1, :flavor_id => "m1.small"}])
    servers.class.should == Plover::Servers
  end
  
end