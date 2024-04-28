@echo off
set RAKE="C:\Program Files\Vagrant\embedded\mingw64\bin\rake.bat"
%RAKE% -f "%~dp0Rakefile" %*

