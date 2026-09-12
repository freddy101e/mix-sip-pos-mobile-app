@echo off
setlocal
set "MIX_SIP_FLUTTER=%USERPROFILE%\develop\bin\flutter.bat"
if not exist "%MIX_SIP_FLUTTER%" (
  echo Flutter SDK was not found at "%MIX_SIP_FLUTTER%".
  exit /b 1
)
if "%~1"=="" (
  call "%MIX_SIP_FLUTTER%" run --dart-define=API_BASE_URL=https://mix-and-sip.devlynq.com/api/v1 --dart-define=API_HOST=
) else (
  call "%MIX_SIP_FLUTTER%" run -d "%~1" --dart-define=API_BASE_URL=https://mix-and-sip.devlynq.com/api/v1 --dart-define=API_HOST=
)
exit /b %ERRORLEVEL%
