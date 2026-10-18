@echo off
echo ========================================
echo   Quick Test Build (Debug Mode)
echo ========================================
echo.

if not exist "pubspec.yaml" (
    echo ERROR: pubspec.yaml not found!
    pause
    exit /b 1
)

echo [1/3] Quick clean...
call flutter clean
echo Done!

echo.
echo [2/3] Getting dependencies...
call flutter pub get
if errorlevel 1 goto error
echo Done!

echo.
echo [3/3] Building debug APK...
echo This is faster than release build (for testing only)
echo.
call flutter build apk --debug
if errorlevel 1 goto error

echo.
echo ========================================
echo     DEBUG BUILD SUCCESSFUL! 
echo ========================================
echo.
echo Debug APK: build\app\outputs\flutter-apk\app-debug.apk
echo.
echo NOTE: This is DEBUG build, not for production!
echo Use build_fix_and_release.bat for production build.
echo.
pause
exit /b 0

:error
echo.
echo Build failed! Check errors above.
pause
exit /b 1
