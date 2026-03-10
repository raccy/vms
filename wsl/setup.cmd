@echo off
@setlocal
set RUBY_BIN_DIR=
for /f "delims=" %%i in ('where.exe ruby.exe 2^>nul') do set "RUBY_BIN_DIR=%%~dpi"
%RUBY_BIN_DIR%ruby.exe %RUBY_BIN_DIR%rake -f "%~dp0Rakefile" %*
@endlocal
