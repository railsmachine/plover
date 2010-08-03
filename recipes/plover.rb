require 'fog'
require 'pathname'
set :rails_root, Pathname.new(ENV['RAILS_ROOT'] || Dir.pwd)
set :fog_servers_yml_path, rails_root.join('config', 'plover.yml')
set :ec2_servers_yml_path, rails_root.join('config', 'plover_servers.yml')

set :fog_servers_yml do
  if fog_servers_yml_path.exist?
    require 'yaml'
    YAML::load(fog_servers_yml_path.read)
  else
    puts "Missing #{fog_servers_yml_path}"
    exit(1)
  end
end

set :ec2_servers_yml do
  if ec2_servers_yml_path.exist?
    require 'yaml'
    YAML::load(ec2_servers_yml_path.read)
  else
    puts "Missing #{ec2_servers_yml_path}"
    exit(1)
  end
end

desc "[internal]: populate capistrano with settings from fog_servers.yml"
task :configure_fog do
  fog_servers_yml.each do |key, value|
    set key.to_sym, value
  end
end

desc "[internal]: populate capistrano with settings from ec2_servers.yml"
task :configure_roles do
  ec2_servers_yml.each do |server_role, servers_list|
    servers_list.each do |server_info|
      role server_role.to_sym, server_info[:dns_name]
    end
  end
end

namespace :plover do
  
  desc "Provision servers at EC2 using Fog"
  task :provision do
    configure_fog
    ec2_servers = {}
    connection = Fog::AWS::EC2.new(:aws_secret_access_key => aws_secret_access_key, :aws_access_key_id => aws_access_key_id)
    servers.each do |type, server|
      server = connection.servers.create(:flavor_id => server["flavor"], :image_id => server["image"], :groups => ["default", "ssh"], :user_data => File.read("config/cloud-config.txt"))
      server.wait_for { ready? }
      puts "#{type} server started as instance #{server.id}"

      if ec2_servers[type].nil?
        ec2_servers[type] = [server_properties(server)]
      else
        ec2_servers[type] << server_properties(server)
      end
    end
    save_server_info(ec2_servers)
  end

  desc "List servers at EC2 using Fog"
  task :list do
    configure_fog
    connection = Fog::AWS::EC2.new(:aws_secret_access_key => aws_secret_access_key, :aws_access_key_id => aws_access_key_id)
    puts connection.servers.inspect
  end
  
  desc "Shutdown servers at EC2 using Fog"
  task :shutdown do
    configure_fog
    connection = Fog::AWS::EC2.new(:aws_secret_access_key => aws_secret_access_key, :aws_access_key_id => aws_access_key_id)
    ec2_servers_yml.each do |server_role, servers_list|
      servers_list.each do |server_info|
        response = connection.servers.get(server_info[:server_id]).destroy
        puts "Server #{server_info[:server_id]} shutdown" if response
      end
    end
  end
  
end

def save_server_info(servers)
  File.open('config/plover_servers.yml', 'w') do |out|
    out.write(servers.to_yaml)
  end
end

def server_properties(server)
  {:server_id => server.id, :dns_name => server.dns_name}
end