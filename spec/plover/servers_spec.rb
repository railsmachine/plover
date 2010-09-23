require 'spec_helper'

describe Plover::Servers do
  before :each do
    Fog::AWS::Compute::Mock.reset_data
    Plover::Connection.establish_connection('aws_access_key_id' => 'user', 'aws_secret_access_key' => 'key')
  end

  describe "when initializing a server list with stale data" do

    before :each do
      old_list = Plover::Servers.new([{:name => 'test_terminated', :role => 'test', :image_id => 1, :flavor_id => "m1.small"}])
      old_list.provision
      old_list.server_list.first.shutdown
      @servers = Plover::Servers.new([{:name => 'test_terminated', :role => 'test', :image_id => 1, :flavor_id => "m1.small"}])
    end

    it "should merge the provided with the running config" do
      @servers.server_list.first.dns_name.should =~ /amazonaws.com/
    end

    it "should load the data from the cloud api to ensure freshness" do
      @servers.server_list.first.state.should == 'shutting-down'
    end
  end

  describe 'provisioning' do
    describe "with customized security groups" do
      before :each do
        @servers = Plover::Servers.new([
          {:name => 'foo1', :image_id => 1, :flavor_id => "m1.small", :group => 'app'},
          {:name => 'foo2', :image_id => 1, :flavor_id => "m1.small", :groups => %w(riak)}
        ])
      end

      it 'provisions servers in the specified security groups' do
        response = Plover.connection.run_instances(1, 1, 1, {'SecurityGroup' => ['default'], 'RamdiskId' => nil, 'BlockDeviceMapping' => nil, 'UserData' => '#cloud-config\n', 'KeyName' => nil, 'KernelId' => nil, 'Monitoring.Enabled' => nil, 'InstanceType' => 'm1.small', 'Placement.AvailabilityZone' => nil})
        Plover.connection.expects(:run_instances).with { |_,_,_,options| options['SecurityGroup'].include?('app') }.returns(response)
        Plover.connection.expects(:run_instances).with { |_,_,_,options| options['SecurityGroup'].include?('riak') }.returns(response)
        @servers.provision
      end
    end

    describe "with default security groups" do
      before :each do
        @servers = Plover::Servers.new([
          {:name => 'foo1', :image_id => 1, :flavor_id => "m1.small", :group => 'app'},
          {:name => 'foo2', :image_id => 1, :flavor_id => "m1.small", :groups => %w(riak)}
        ])
      end

      it ".provision should start instances in the default security group" do
        @servers.provision
      end

      it ".request_boot should output booting status" do
        @servers.request_bootup
        server_output = YAML.load_file('config/plover_servers.yml')
        server_output.should_not be_empty
        server_output.each do |server|
          server[:name].should =~ /foo/
          server[:state].should == 'booting'
        end
      end

      it ".provision should output running status" do
        @servers.provision
        server_output = YAML.load_file('config/plover_servers.yml')
        server_output.should_not be_empty
        server_output.each do |server|
          server[:name].should =~ /foo/
          server[:state].should == 'running'
        end
      end

      it ".boot should write out server info even when failure occurs" do
        provisioning = sequence('provisioning')
        response = Plover.connection.run_instances(1, 1, 1, {'SecurityGroup' => ['default'], 'RamdiskId' => nil, 'BlockDeviceMapping' => nil, 'UserData' => '#cloud-config\n', 'KeyName' => nil, 'KernelId' => nil, 'Monitoring.Enabled' => nil, 'InstanceType' => 'm1.small', 'Placement.AvailabilityZone' => nil})
        Plover.connection.expects(:run_instances).with { |_,_,_,options| options['SecurityGroup'].include?('app') }.returns(response).in_sequence(provisioning)
        Plover.connection.expects(:run_instances).with { |_,_,_,options| options['SecurityGroup'].include?('riak') }.raises(StandardError).in_sequence(provisioning)
        lambda {
          @servers.provision
        }.should raise_error(StandardError)
        server_output = YAML.load_file('config/plover_servers.yml')
        server_output.should_not be_empty
        server_output.first[:state].should == 'booting'
        server_output.last[:state].should == 'exception'
      end
    end

    describe "when a server was last seen in a booting state, but has since started" do
      before :each do
        old_list = Plover::Servers.new([{:name => 'test_running', :role => 'test', :image_id => 1, :flavor_id => "m1.small"}])
        old_list.request_bootup
        old_list.server_list.first.update_once_running
        @servers = Plover::Servers.new([{:name => 'test_running', :role => 'test', :image_id => 1, :flavor_id => "m1.small"}])
      end

      it "should detect server is running" do
        @servers.server_list.first.state.should == 'running'
      end

      it ".boot should not start duplicate instances" do
        Plover.connection.expects(:run_instances).never
        @servers.provision
      end

    end

    describe "when a server immediately terminates" do
      before :each do
        @servers = Plover::Servers.new([{:name => 'test_terminated', :role => 'test', :image_id => 1, :flavor_id => "m1.small"}])
        @servers.request_bootup
        new_data = {"instanceState"=>{"name"=>"terminated", "code"=>0}, "reason"=>"Server.InternalError"}
        instance_id, instance_data = Fog::AWS::Compute::Mock.data["user"][:instances].first
        new_instance_data = instance_data.merge(new_data)
        mock_data = Fog::AWS::Compute::Mock.data
        mock_data["user"][:instances] = {instance_id => new_instance_data }
        Fog::AWS::Compute::Mock.instance_variable_set("@data", mock_data)
      end

      it "should detect server has terminated" do
        @servers.request_info
        @servers.server_list.first.state.should == 'terminated'
        @servers.server_list.first.reason.should == 'Server.InternalError'
      end

    end

  end

end