module Plover
  class Files
  
    attr_reader :yaml_hash
  
    def initialize(file)
      @path = file
      @yaml_hash = YAML.load(File.read(@path))
    end
  
    def by_role(role)
      @yaml_hash.select {|server| server[:role] == role}
    end

    def by_roles(*roles)
      @yaml_hash.select {|server| roles.include?(server[:role])}
    end

    def write
      File.open(@path, 'w') do |out|
        puts "Writing out #{@path}"
        out.write(@yaml_hash.to_yaml)
      end
    end
  
  end
end