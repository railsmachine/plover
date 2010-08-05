require 'spec_helper'

describe Plover::Servers do
  
  it "should raise an error when missing a username and api key" do
    lambda {
      Plover::Servers.new
    }.should raise_error(ArgumentError)
  end
  
  it "should create an ec2 connection when given a proper username and api key" do
    Plover::Servers.new("connection", {:image => 1, :flavor => "m1.small"})
  end
  
end