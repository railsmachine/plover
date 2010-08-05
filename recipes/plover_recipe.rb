require 'lib/plover'
require 'pathname'
set :rails_root, Pathname.new(ENV['RAILS_ROOT'] || Dir.pwd)
set :plover_yml_path, rails_root.join('config', 'plover.yml')
set :plover_cloud_config_path, rails_root.join('config', 'cloud-config.txt')

set :plover_yml do
  if plover_yml_path.exist?
    require 'yaml'
    YAML::load(plover_yml_path.read)
  else
    puts "Missing #{plover_yml_path}"
    exit(1)
  end
end

desc "[internal]: populate capistrano with settings from plover.yml"
task :configure_plover do
  plover_yml.each do |key, value|
    set key.to_sym, value
  end
end

desc "[internal]: populate capistrano with settings from plover_servers.yml"
task :configure_roles do
  plover_servers_yml.each do |server_role, servers_list|
    servers_list.each do |server_info|
      role server_role.to_sym, server_info[:dns_name]
    end
  end
end

namespace :plover do
  
  desc "Provision servers at EC2 using Plover"
  task :provision do
    configure_plover
    plover = Plover::Connection.new(aws_access_key_id, aws_secret_access_key)
    plover.provision_servers(servers)
  end

  desc "List servers at EC2 started by Plover"
  task :list do
    configure_plover
    plover = Plover::Connection.new(aws_access_key_id, aws_secret_access_key)
    puts plover.running_servers.inspect
  end
  
  desc "List servers at EC2 started by Plover"
  task :list_fog do
    configure_plover
    plover = Plover::Connection.new(aws_access_key_id, aws_secret_access_key)
    puts plover.servers.inspect
  end
  
  desc "List servers at EC2 using Plover"
  task :list_roles do
    configure_plover
    connection = Plover::Connection.new(aws_access_key_id, aws_secret_access_key)
    Plover::Connection.load_roles(plover_servers_yml)
    puts "Roles: #{roles.inspect}"
  end
  
  desc "Shutdown servers at EC2 using Plover"
  task :shutdown do
    configure_plover
    plover = Plover::Connection.new(aws_access_key_id, aws_secret_access_key)
    plover.shutdown_servers
  end
  
end

