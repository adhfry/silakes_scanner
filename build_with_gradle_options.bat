@echo off
echo ========================================
echo  Build with Custom Gradle Options
echo ========================================
echo.

if not exist "pubspec.yaml" (
    echo ERROR: Not in project root!
    pause
    exit /b 1
)

echo [1/9] Stopping Gradle daemon...
cd android
call gradlew --stop
cd ..
echo Done!

echo.
echo [2/9] Killing processes...
taskkill /F /IM java.exe 2>nul
taskkill /F /IM gradle.exe 2>nul
timeout /t 3 >nul
echo Done!

echo.
echo [3/9] Flutter clean...
call flutter clean
echo Done!

echo.
echo [4/9] Deleting build folders...
if exist "build\" rmdir /s /q build 2>nul
if exist "android\build\" rmdir /s /q android\build 2>nul
if exist "android\app\build\" rmdir /s /q android\app\build 2>nul
timeout /t 2 >nul
echo Done!

echo.
echo [5/9] Getting dependencies...
call flutter pub get
if errorlevel 1 goto error
echo Done!

echo.
echo [6/9] Generating code...
call dart run build_runner build --delete-conflicting-outputs
if errorlevel 1 (
    echo WARNING: Build runner issues, continuing...
)
echo Done!

echo.
echo [7/9] Setting Gradle options...
echo.
echo Creating gradle.properties with optimized settings...

(
echo org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=1024m -XX:+HeapDumpOnOutOfMemoryError
echo org.gradle.daemon=true
echo org.gradle.parallel=true
echo org.gradle.caching=false
echo org.gradle.configureondemand=false
echo kotlin.incremental=false
echo kotlin.compiler.execution.strategy=out-of-process
echo android.enableJetifier=true
echo android.useAndroidX=true
) > android\gradle.properties

echo Done!

echo.
echo [8/9] Building APK with custom flags...
echo This may take 10-15 minutes...
echo.

:: Build dengan options khusus untuk avoid cache issues
call flutter build apk --release ^
    --no-shrink ^
    --no-tree-shake-icons ^
    --dart-define=FLUTTER_WEB_USE_SKIA=false

if errorlevel 1 goto error

echo.
echo [9/9] Checking output...
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo.
    echo ========================================
    echo       BUILD SUCCESSFUL! 
    echo ========================================
    echo.
    echo APK: %CD%\build\app\outputs\flutter-apk\app-release.apk
    echo.
    
    for %%F in ("build\app\outputs\flutter-apk\app-release.apk") do (
        set /a sizeMB=%%~zF/1048576
    )
    echo Size: !sizeMB! MB
    echo.
    
    set /p OPEN="Open folder? (Y/N): "
    if /i "%OPEN%"=="Y" explorer "build\app\outputs\flutter-apk\"
) else (
    echo APK not found! Check errors above.
)

echo.
pause
exit /b 0

:error
echo.
echo ========================================
echo       BUILD FAILED!
echo ========================================
echo.
echo Try: nuclear_clean_and_build.bat
echo.
pause
exit /b 1
