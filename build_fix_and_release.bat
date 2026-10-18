@echo off
echo ========================================
echo  SiLAKES Scanner - Fix and Build APK
echo ========================================
echo.

:: Check if we're in the right directory
if not exist "pubspec.yaml" (
    echo ERROR: pubspec.yaml not found!
    echo Please run this script from the project root directory.
    pause
    exit /b 1
)

echo [1/8] Stopping Gradle daemon...
cd android
call gradlew --stop
cd ..
echo Done!

echo.
echo [2/8] Cleaning Flutter project...
call flutter clean
if errorlevel 1 goto error
echo Done!

echo.
echo [3/8] Deleting build cache folders...
if exist "build\" (
    echo Deleting build folder...
    rmdir /s /q build 2>nul
    timeout /t 2 >nul
)
if exist ".dart_tool\" (
    echo Deleting .dart_tool folder...
    rmdir /s /q .dart_tool 2>nul
    timeout /t 2 >nul
)
if exist "android\.gradle\" (
    echo Deleting android .gradle folder...
    rmdir /s /q android\.gradle 2>nul
    timeout /t 2 >nul
)
if exist "android\build\" (
    echo Deleting android build folder...
    rmdir /s /q android\build 2>nul
    timeout /t 2 >nul
)
if exist "android\app\build\" (
    echo Deleting android app build folder...
    rmdir /s /q android\app\build 2>nul
    timeout /t 2 >nul
)
echo Done!

echo.
echo [4/8] Getting Flutter dependencies...
call flutter pub get
if errorlevel 1 goto error
echo Done!

echo.
echo [5/8] Generating Hive adapters...
call dart run build_runner build --delete-conflicting-outputs
if errorlevel 1 (
    echo WARNING: Build runner had issues, but continuing...
)
echo Done!

echo.
echo [6/8] Running Flutter doctor (quick check)...
call flutter doctor
echo.

echo.
echo [7/8] Building Release APK...
echo This may take 5-10 minutes, please wait...
echo.
call flutter build apk --release --no-shrink
if errorlevel 1 goto error

echo.
echo [8/8] Checking APK output...
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo.
    echo ========================================
    echo       BUILD SUCCESSFUL! 
    echo ========================================
    echo.
    echo APK Location:
    echo %CD%\build\app\outputs\flutter-apk\app-release.apk
    echo.
    
    :: Get file size
    for %%F in ("build\app\outputs\flutter-apk\app-release.apk") do (
        set size=%%~zF
        set /a sizeMB=%%~zF/1048576
    )
    echo APK Size: !sizeMB! MB
    echo.
    echo APK is ready for distribution!
    echo ========================================
    echo.
    
    :: Ask if want to open folder
    echo.
    set /p OPEN="Open APK folder? (Y/N): "
    if /i "%OPEN%"=="Y" (
        explorer "build\app\outputs\flutter-apk\"
    )
) else (
    echo.
    echo ========================================
    echo       BUILD COMPLETED
    echo ========================================
    echo.
    echo APK file not found in expected location.
    echo Please check build output above for errors.
    echo.
)

echo.
echo Press any key to exit...
pause >nul
exit /b 0

:error
echo.
echo ========================================
echo          BUILD FAILED! 
echo ========================================
echo.
echo Please check the error messages above.
echo.
echo Common solutions:
echo 1. Make sure you have stable internet connection
echo 2. Try running this script again
echo 3. Check if Android SDK is properly installed
echo 4. Make sure Flutter is up to date (flutter upgrade)
echo.
pause
exit /b 1
