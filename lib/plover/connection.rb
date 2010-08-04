module Plover
  
  class Connection
    
    attr_accessor :connection
    
    def initialize(id, key)
      @connection = Fog::AWS::EC2.new(:aws_access_key_id => id, :aws_secret_access_key => key)
    end
    
  end

end