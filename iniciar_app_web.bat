@echo off
setlocal

cd /d "%~dp0"

echo Iniciando app Flutter Web en http://127.0.0.1:52222
flutter run -d chrome --web-hostname 127.0.0.1 --web-port 52222

endlocal
