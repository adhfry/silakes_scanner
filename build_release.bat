@echo off
echo ========================================
echo    SiLAKES Scanner - Release Build
echo ========================================
echo.

:: Check if we're in the right directory
if not exist "pubspec.yaml" (
    echo ERROR: pubspec.yaml not found!
    echo Please run this script from the project root directory.
    pause
    exit /b 1
)

echo [1/6] Cleaning previous builds...
call flutter clean
if errorlevel 1 goto error

echo.
echo [2/6] Getting dependencies...
call flutter pub get
if errorlevel 1 goto error

echo.
echo [3/6] Running code analysis...
call flutter analyze --no-fatal-infos
if errorlevel 1 (
    echo WARNING: Analysis found issues, but continuing...
)

echo.
echo [4/6] Generating Hive adapters...
call flutter pub run build_runner build --delete-conflicting-outputs
if errorlevel 1 goto error

echo.
echo [5/6] Building Release APK...
echo This may take several minutes...
call flutter build apk --release
if errorlevel 1 goto error

echo.
echo [6/6] Building Release App Bundle (AAB)...
call flutter build appbundle --release
if errorlevel 1 goto error

echo.
echo ========================================
echo         BUILD SUCCESSFUL! 
echo ========================================
echo.
echo APK Location:
echo build\app\outputs\flutter-apk\app-release.apk
echo.
echo AAB Location:
echo build\app\outputs\bundle\release\app-release.aab
echo.
echo File Sizes:
for %%F in ("build\app\outputs\flutter-apk\app-release.apk") do echo APK: %%~zF bytes
for %%F in ("build\app\outputs\bundle\release\app-release.aab") do echo AAB: %%~zF bytes
echo.
echo Ready for distribution!
echo ========================================
pause
exit /b 0

:error
echo.
echo ========================================
echo          BUILD FAILED! 
echo ========================================
echo.
echo Please check the error messages above.
echo.
pause
exit /b 1
