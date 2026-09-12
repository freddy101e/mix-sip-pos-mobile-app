@echo off
setlocal
set "MIX_SIP_FLUTTER=%USERPROFILE%\develop\bin\flutter.bat"
if not exist "%MIX_SIP_FLUTTER%" (
  echo Flutter SDK was not found at "%MIX_SIP_FLUTTER%".
  exit /b 1
)
call "%MIX_SIP_FLUTTER%" %*
exit /b %ERRORLEVEL%
