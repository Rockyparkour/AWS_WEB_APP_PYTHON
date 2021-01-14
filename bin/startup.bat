@echo off
set FUSIONAUTH_JAVA_DIR=%~dp0..\java
set JAVA_VERSION=14.0.1
set JAVA_REVISION=7

echo Starting fusionauth-search ...
IF EXIST %~dp0..\fusionauth-search (
  Powershell.exe -executionpolicy ByPass -File %~dp0..\fusionauth-search\elasticsearch\bin\install_java.ps1
  START "fusionauth-search" /D %~dp0..\fusionauth-search\elasticsearch\bin elasticsearch
) ELSE (
  echo skipped, not installed.
)

echo Starting fusionauth-app ...
IF EXIST "%~dp0..\fusionauth-app" (
  Powershell.exe -executionpolicy ByPass -File %~dp0..\fusionauth-app\apache-tomcat\bin\install_java.ps1
  START "fusionauth-app" /D %~dp0..\fusionauth-app\apache-tomcat\bin catalina.bat start
) ELSE (
  echo skipped, not installed.
)
