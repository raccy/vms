# create wsl

require 'open3'

def install_wsl(distro, user:, password:, version: 2)
  wsl_list = `wsl --list --verbose`
  m = /^\*?\s+#{distro}\s+(\w+)\s+(\d)$/.match(wsl_list)
  if m.nil?
    Open3.popen2('wsl', '--install', distro) do |stdin, stdout, _thr|
      stdin.puts user
      stdin.puts password
      stdin.puts password
      stdin.puts 'exit'
      stdin.close
      print stdout.read
      # puts 'wsl...'
      # buff = String.new
      # loop do
      #   pp 'loop'
      #   pp stdout.getc
      #   stdout.readpartial(1024, buff)
      #   pp buff
      #   case buff
      #   when /Enter new UNIX username:/
      #     buff.clear
      #     stdin.puts(user)
      #     stdin.flush
      #   when /New password:/, /Retype new password:/
      #     buff.clear
      #     stdin.puts(password)
      #     stdin.flush
      #   when /\[[^\]]*\]\$/
      #     buff.clear
      #     stdin.puts('exit')
      #     stdin.flush
      #   when /logout/
      #     stdin.close
      #     stdout.close
      #     break
      #   end
      # end
    end
  end
end

distro = 'OracleLinux_9_1'
install_wsl(distro, user: 'whs', password: 'whs')

__END__

@ECHO OFF
SETLOCAL
SET DISTRO=OracleLinux_9_1
SET WSL_LIST="%~dp0\wsl_list.txt"

wsl --list --verbose > %WSL_LIST%

FINDSTR "%DISTRO%.*1$" %WSL_LIST%
IF %ERRORLEVEL% EQU 0 GOTO SKIP_SET_VERSION

FINDSTR "%DISTRO%" %WSL_LIST%
IF %ERRORLEVEL% EQU 0 GOTO SKIP_INSTALL

ECHO ---- Intall Linux ----
wsl --install %DISTRO%
IF %ERRORLEVEL% NEQ 0 GOTO ERR
:SKIP_INSTALL

echo ---- Set WSL versinon 1 ----
wsl --set-version %DISTRO% 1
IF %ERRORLEVEL% NEQ 0 GOTO ERR
:SKIP_SET_VERSION

echo ---- Setup ----
wsl --distribution  %DISTRO% ./setup.sh
IF %ERRORLEVEL% NEQ 0 GOTO ERR

GOTO :EOF

:ERR
ECHO.
ECHO Error has occurred!
PAUSE

ENDLOCAL
