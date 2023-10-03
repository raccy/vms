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
