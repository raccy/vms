#!/bin/env ruby

# version 1.0.20220111

if $0 == __FILE__
  Dir.chdir(ARGV[0]) if ARGV[0]
  name = File.basename(Dir.pwd).gsub('_', '-')
  ssh_config_file = File.expand_path("./.ssh/hosts/#{name}", ENV['HOME'])
  vagrant_ssh_config = `vagrant ssh-config --host #{name}`
  IO.write(ssh_config_file, vagrant_ssh_config)  
end
