@echo off
rem CampusCare - run the whole project on this PC with one command:
rem
rem     code\windows\run.bat          (or just double-click this file)
rem
rem The first run downloads what it needs (about 3 GB) into code\.tools.
rem Nothing is installed on the PC itself. Later runs start in a minute or two.
setlocal
title CampusCare - local run
cd /d "%~dp0.."

set "TOOLS=%CD%\.tools"
set "PY=%TOOLS%\python\python.exe"
set "PYURL=https://github.com/astral-sh/python-build-standalone/releases/download/20261123/cpython-3.12.16%%2B20261123-x86_64-pc-windows-msvc-install_only_stripped.tar.gz"

if exist "%PY%" goto run

if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" goto cpuok
if /i "%PROCESSOR_ARCHITEW6432%"=="AMD64" goto cpuok
echo.
echo   PROBLEM: this needs a 64-bit Intel or AMD Windows PC.
goto end

:cpuok
if not exist "%SystemRoot%\System32\curl.exe" goto oldwindows
if not exist "%SystemRoot%\System32\tar.exe" goto oldwindows

echo.
echo   CampusCare - first run.
echo   Downloading what it needs (about 3 GB) into this folder.
echo   Nothing is installed on your PC. Please keep this window open.
echo.
if not exist "%TOOLS%" mkdir "%TOOLS%"
"%SystemRoot%\System32\curl.exe" -fL -# --retry 5 --connect-timeout 30 -C - -o "%TOOLS%\python.tar.gz" "%PYURL%"
if errorlevel 1 goto downloadfailed
if exist "%TOOLS%\python" rmdir /s /q "%TOOLS%\python"
"%SystemRoot%\System32\tar.exe" -xf "%TOOLS%\python.tar.gz" -C "%TOOLS%"
if errorlevel 1 goto downloadfailed
del "%TOOLS%\python.tar.gz"

:run
"%PY%" -E -s launcher\run.py %*
goto end

:oldwindows
echo.
echo   PROBLEM: this needs Windows 10 (2018 update or newer) or Windows 11.
goto end

:downloadfailed
if exist "%TOOLS%\python.tar.gz" del "%TOOLS%\python.tar.gz"
echo.
echo   PROBLEM: the download did not finish.
echo   Check the internet connection and run this file again.

:end
echo.
pause
