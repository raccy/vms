#!/bin/env ruby

# version 1.0.20220111

if $0 == __FILE__
  distrib = 'Ubuntu'
  ssh_hosts = '.ssh/hosts'

  hostname = `hostname`.chomp
  username = ENV['USERNAME']
  user_sid = "#{hostname.upcase}\\#{username}"

  wsl_home = `wsl -d #{distrib} printenv HOME`.chomp

  lin_home_path = "//wsl.localhost/#{distrib}#{wsl_home}"
  lin_ssh_hosts = "#{lin_home_path}/#{ssh_hosts}"

  win_home_path = ENV['USERPROFILE'].tr('\\', '/')
  win_ssh_hosts = "#{win_home_path}/#{ssh_hosts}"

  Dir.each_child(lin_ssh_hosts) do |file|
    next if file.start_with?('.')

    data = IO.read("#{lin_ssh_hosts}/#{file}")
    data.gsub!(%r{/mnt/([a-z])/}) { $1.upcase + ':/' }
    if data =~ /^\s+IdentityFile\s+(\S+)\s*$/
      identity_file = $1
      if FileTest.file?(identity_file)
        system('icacls', identity_file, '/grant:r', "#{user_sid}:(F)")
        system('icacls', identity_file, '/inheritance:r')
      end
    end
    IO.write("#{win_ssh_hosts}/#{file}", data)
    puts file
  end
end
