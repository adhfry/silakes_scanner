@echo off
setlocal enabledelayedexpansion
echo ========================================
echo   NUCLEAR CLEAN - Maximum Cache Clear
echo ========================================
echo.
echo This will:
echo - Kill ALL Java/Gradle/Kotlin processes
echo - Delete ALL build caches
echo - Clear Gradle cache completely
echo - Delete Android Studio caches
echo - Restart from scratch
echo.
echo WARNING: This is AGGRESSIVE cleanup!
echo.
set /p CONFIRM="Continue? (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo Cancelled.
    pause
    exit /b 0
)

echo.
echo ========================================
echo   STEP 1: Kill All Related Processes
echo ========================================
echo.
echo Killing Java processes...
taskkill /F /IM java.exe 2>nul
taskkill /F /IM javaw.exe 2>nul
timeout /t 2 >nul

echo Killing Gradle processes...
taskkill /F /IM gradle.exe 2>nul
taskkill /F /IM gradlew.exe 2>nul
timeout /t 2 >nul

echo Killing Kotlin processes...
taskkill /F /IM kotlin.exe 2>nul
taskkill /F /IM kotlinc.exe 2>nul
timeout /t 2 >nul

echo All processes killed!
timeout /t 3 >nul

echo.
echo ========================================
echo   STEP 2: Stop Gradle Daemon
echo ========================================
echo.
cd android 2>nul
call gradlew --stop 2>nul
cd ..
timeout /t 2 >nul
echo Done!

echo.
echo ========================================
echo   STEP 3: Flutter Clean
echo ========================================
echo.
call flutter clean
timeout /t 2 >nul
echo Done!

echo.
echo ========================================
echo   STEP 4: Delete Project Build Folders
echo ========================================
echo.
echo Deleting build folder...
if exist "build\" (
    rmdir /s /q build 2>nul
    if exist "build\" (
        echo Folder still exists, trying forcefully...
        rd /s /q build
    )
    timeout /t 2 >nul
)

echo Deleting .dart_tool...
if exist ".dart_tool\" (
    rmdir /s /q .dart_tool 2>nul
    timeout /t 1 >nul
)

echo Deleting .flutter-plugins...
del /f /q .flutter-plugins 2>nul
del /f /q .flutter-plugins-dependencies 2>nul

echo Done!

echo.
echo ========================================
echo   STEP 5: Delete Android Build Caches
echo ========================================
echo.
echo Deleting android\.gradle...
if exist "android\.gradle\" (
    rmdir /s /q android\.gradle 2>nul
    timeout /t 2 >nul
)

echo Deleting android\build...
if exist "android\build\" (
    rmdir /s /q android\build 2>nul
    timeout /t 2 >nul
)

echo Deleting android\app\build...
if exist "android\app\build\" (
    rmdir /s /q android\app\build 2>nul
    timeout /t 2 >nul
)

echo Deleting android\.idea...
if exist "android\.idea\" (
    rmdir /s /q android\.idea 2>nul
)

echo Deleting android local files...
del /f /q android\local.properties 2>nul
del /f /q android\.classpath 2>nul
del /f /q android\.project 2>nul

echo Done!

echo.
echo ========================================
echo   STEP 6: Clear Gradle User Cache
echo ========================================
echo.
echo Clearing Gradle daemon cache...
if exist "%USERPROFILE%\.gradle\daemon\" (
    rmdir /s /q "%USERPROFILE%\.gradle\daemon\" 2>nul
    timeout /t 2 >nul
)

echo Clearing Gradle caches...
if exist "%USERPROFILE%\.gradle\caches\" (
    echo This may take a while...
    rmdir /s /q "%USERPROFILE%\.gradle\caches\" 2>nul
    timeout /t 3 >nul
)

echo Done!

echo.
echo ========================================
echo   STEP 7: Clear Kotlin Cache
echo ========================================
echo.
if exist "%USERPROFILE%\.kotlin\" (
    echo Clearing Kotlin cache...
    rmdir /s /q "%USERPROFILE%\.kotlin\" 2>nul
)
echo Done!

echo.
echo ========================================
echo   STEP 8: Clear Flutter Pub Cache
echo ========================================
echo.
echo Clearing pub cache (this will re-download packages)...
call flutter pub cache clean
echo Done!

echo.
echo ========================================
echo   STEP 9: Get Fresh Dependencies
echo ========================================
echo.
call flutter pub get
if errorlevel 1 (
    echo.
    echo ERROR: Failed to get dependencies!
    echo Check your internet connection and try again.
    pause
    exit /b 1
)
echo Done!

echo.
echo ========================================
echo   STEP 10: Generate Hive Adapters
echo ========================================
echo.
call dart run build_runner build --delete-conflicting-outputs
if errorlevel 1 (
    echo WARNING: Build runner had issues
    echo Continuing anyway...
)
echo Done!

echo.
echo ========================================
echo   STEP 11: Build APK (with --no-incremental)
echo ========================================
echo.
echo Building APK without incremental compilation...
echo This will take 10-15 minutes...
echo.
call flutter build apk --release --no-shrink --no-incremental
if errorlevel 1 goto buildfailed

echo.
echo ========================================
echo       BUILD SUCCESSFUL! 
echo ========================================
echo.
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo APK Location:
    echo %CD%\build\app\outputs\flutter-apk\app-release.apk
    echo.
    
    for %%F in ("build\app\outputs\flutter-apk\app-release.apk") do (
        set /a sizeMB=%%~zF/1048576
    )
    echo APK Size: !sizeMB! MB
    echo.
    echo APK is ready for distribution!
    echo.
    
    set /p OPEN="Open APK folder? (Y/N): "
    if /i "!OPEN!"=="Y" (
        explorer "build\app\outputs\flutter-apk\"
    )
) else (
    echo APK file not found!
    echo Please check build output above.
)

echo.
echo ========================================
echo   Cleanup Complete!
echo ========================================
pause
exit /b 0

:buildfailed
echo.
echo ========================================
echo       BUILD FAILED!
echo ========================================
echo.
echo If build still fails after nuclear clean:
echo.
echo 1. Restart your computer
echo 2. Check if antivirus is blocking files
echo 3. Run this script as Administrator
echo 4. Check disk space (need at least 5GB free)
echo 5. Update Flutter: flutter upgrade
echo.
echo If problem persists, there might be a deeper issue.
echo Check the JVM crash log: android\hs_err_pid*.log
echo.
pause
exit /b 1
