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
  
end