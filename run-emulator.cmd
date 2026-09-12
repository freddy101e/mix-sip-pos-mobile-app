@echo off
setlocal
set "MIX_SIP_FLUTTER=%USERPROFILE%\develop\bin\flutter.bat"
if not exist "%MIX_SIP_FLUTTER%" (
  echo Flutter SDK was not found at "%MIX_SIP_FLUTTER%".
  exit /b 1
)
call "%MIX_SIP_FLUTTER%" run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2/api/v1 --dart-define=API_HOST=pos.test
exit /b %ERRORLEVEL%
