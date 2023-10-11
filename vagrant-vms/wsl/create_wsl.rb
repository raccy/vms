# create wsl

distro = 'OracleLinux_9_1'

wsl_list = `wsl --list --verbose`.encode('UTF-8', 'UTF-16LE')
m = /^\*?\s+#{distro}\s+\w+\s+(\d)$/.match(wsl_list)
system("wsl --install #{distro}") if m.nil?
system("wsl --set-version #{distro} 1") if m.nil? || m[1] != '1'
system("wsl --distribution #{distro} --cd \"#{__dir__}\" -- ./setup.sh")
