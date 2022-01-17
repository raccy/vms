#!/bin/env ruby

# version 1.1.20220114

if $0 == __FILE__
  Dir.chdir(ARGV[0]) if ARGV[0]
  name = File.basename(Dir.pwd).gsub('_', '-')
  ssh_config_file = File.join(ENV['HOME'], '.ssh', 'hosts', name)
  vagrant_ssh_config = `vagrant ssh-config --host #{name}`
  IO.write(ssh_config_file, vagrant_ssh_config)

  # WSL only
  if RUBY_PLATFORM =~ /linux/i && `uname -r` =~ /microsoft/i
    win_host = `hostname.exe`.chomp
    win_user = `powershell.exe '$env:USERNAME'`.chomp
    win_home = `powershell.exe '$env:USERPROFILE'`.chomp
    win_home_wslpath = `wslpath '#{win_home}'`.chomp

    win_ssh_config_file = File.join(win_home_wslpath, '.ssh', 'hosts', name)

    win_vagrant_ssh_config = vagrant_ssh_config.gsub(%r{(?<=\s)/mnt/[a-z]/.*}) do |path|
      `wslpath -m '#{path}'`.chomp
    end
    IO.write(win_ssh_config_file, win_vagrant_ssh_config)

    if win_vagrant_ssh_config =~ /^\s+IdentityFile\s+(\S+)\s*$/
      identity_file = $1
      user_sid = "#{win_host.upcase}\\#{win_user}"
      system('icacls.exe', identity_file, '/grant:r', "#{user_sid}:(F)")
      system('icacls.exe', identity_file, '/inheritance:r')
    end
  end
end
