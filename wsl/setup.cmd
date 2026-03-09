@echo off
set RAKE="rake.bat"
%RAKE% -f "%~dp0Rakefile" %*
