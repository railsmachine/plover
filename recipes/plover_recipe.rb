require  File.join(File.dirname(__FILE__), '../lib/plover')
require 'pathname'

desc "[internal]: populate capistrano with settings from plover.yml"
task :configure_plover do
  Plover.file_root                  = Pathname.new(ENV['RAILS_ROOT'] || Dir.pwd)
  Plover.cloud_config_path          = fetch(:cloud_config_path, nil)
  Plover.plover_config_path         = fetch(:plover_config_path, nil)
  Plover.plover_servers_config_path = fetch(:plover_servers_config_path, nil)
  Plover::Connection.establish_connection
end

desc "[internal]: populate capistrano with settings from plover_servers.yml"
task :configure_plover_roles do
  configure_plover
  Plover::Connection.server_list.each do |server|
    if server.options.nil?
      role server.role.to_sym, server.dns_name
    else
      role server.role.to_sym, server.dns_name, server.options
    end
  end
end

namespace :plover do
  
  desc "Provision servers at EC2 using Plover"
  task :provision do
    configure_plover
    Plover::Connection.provision_servers
  end

  desc "List servers at EC2 started by Plover"
  task :list do
    configure_plover
    Plover::Connection.running_servers
  end
  
  desc "List servers at EC2 started by Plover"
  task :list_fog do
    configure_plover
    puts Plover::Connection.servers.inspect
  end
  
  desc "List servers at EC2 using Plover"
  task :list_roles do
    configure_plover_roles
    puts "Roles: #{roles.inspect}"
  end
  
  desc "Shutdown servers at EC2 using Plover"
  task :shutdown do
    configure_plover
    Plover::Connection.shutdown_servers
  end
  
end