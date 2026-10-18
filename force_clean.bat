@echo off
echo ========================================
echo   Force Clean - Remove All Cache
echo ========================================
echo.
echo WARNING: This will delete all build files and cache!
echo.
set /p CONFIRM="Are you sure? (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo Cancelled.
    pause
    exit /b 0
)

echo.
echo [1/7] Stopping Gradle daemon...
cd android 2>nul
call gradlew --stop 2>nul
cd ..
echo Done!

echo.
echo [2/7] Killing any Java/Gradle processes...
taskkill /F /IM java.exe 2>nul
taskkill /F /IM gradle.exe 2>nul
timeout /t 2 >nul
echo Done!

echo.
echo [3/7] Running Flutter clean...
call flutter clean
echo Done!

echo.
echo [4/7] Deleting build folders...
if exist "build\" (
    echo - Deleting build...
    rmdir /s /q build 2>nul
    timeout /t 1 >nul
)
if exist ".dart_tool\" (
    echo - Deleting .dart_tool...
    rmdir /s /q .dart_tool 2>nul
    timeout /t 1 >nul
)
if exist ".flutter-plugins" (
    del /f /q .flutter-plugins 2>nul
)
if exist ".flutter-plugins-dependencies" (
    del /f /q .flutter-plugins-dependencies 2>nul
)
echo Done!

echo.
echo [5/7] Deleting Android build folders...
if exist "android\.gradle\" (
    echo - Deleting android\.gradle...
    rmdir /s /q android\.gradle 2>nul
    timeout /t 1 >nul
)
if exist "android\build\" (
    echo - Deleting android\build...
    rmdir /s /q android\build 2>nul
    timeout /t 1 >nul
)
if exist "android\app\build\" (
    echo - Deleting android\app\build...
    rmdir /s /q android\app\build 2>nul
    timeout /t 1 >nul
)
if exist "android\.idea\" (
    echo - Deleting android\.idea...
    rmdir /s /q android\.idea 2>nul
)
echo Done!

echo.
echo [6/7] Clearing Flutter cache (pub-cache)...
call flutter pub cache clean
echo Done!

echo.
echo [7/7] Getting fresh dependencies...
call flutter pub get
if errorlevel 1 (
    echo ERROR: Failed to get dependencies!
    pause
    exit /b 1
)
echo Done!

echo.
echo ========================================
echo    Force Clean Complete!
echo ========================================
echo.
echo All cache cleared. Project is clean.
echo You can now run build_fix_and_release.bat
echo.
pause
