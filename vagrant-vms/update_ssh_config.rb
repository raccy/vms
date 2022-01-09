#!/bin/env ruby
# frozen_string_literal: true

# version 1.1.20201223

def parse_ssh_config(data)
  config = {}
  hosts = {}
  host = nil
  data.each_line do |line|
    line.strip!
    next if line.empty? || line.start_with?('#')
    if line =~ /^(\w+)\s+(\S.*)$/
      key = $1
      value = $2
      if key == 'Host'
        host = value
        hosts[host] ||= {}
      elsif host
        hosts[host][key] = value
      else
        config[key] = value
      end
    else
      raise "invalid or not support format line: #{line}"
    end
  end
  {config: config, hosts: hosts}
end

def print_ssh_config(out, data)
  data[:config].each_pair do |key, value|
    out << "#{key} #{value}\n"
  end
  data[:hosts].each_pair do |host, config|
    out << "Host #{host}\n"
    config.each_pair do |key, value|
      out << "  #{key} #{value}\n"
    end
  end
end

if $0 == __FILE__
  name = File.basename(File.absolute_path(__dir__)).gsub('_', '-')

  ssh_config = File.expand_path('./.ssh/config', ENV['HOME'])

  config_data = parse_ssh_config(IO.read(ssh_config))
  vagrant_data = parse_ssh_config(`vagrant ssh-config --host #{name}`)

  merge_data = {
    config: config_data[:config].merge(vagrant_data[:config]),
    hosts: config_data[:hosts].merge(vagrant_data[:hosts])
  }

  str = String.new
  print_ssh_config(str, merge_data)

  IO.write(ssh_config, str)
end
