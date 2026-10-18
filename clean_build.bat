@echo off
echo ========================================
echo    SiLAKES Scanner - Clean Build
echo ========================================
echo.

echo Cleaning build files...
call flutter clean

echo.
echo Getting dependencies...
call flutter pub get

echo.
echo Generating Hive adapters...
call flutter pub run build_runner build --delete-conflicting-outputs

echo.
echo ========================================
echo      Clean Build Complete!
echo ========================================
echo.
echo You can now run:
echo   - flutter run (debug)
echo   - flutter run --release
echo   - Or use build_release.bat
echo.
pause
