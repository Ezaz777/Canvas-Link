@echo off
REM ============================================================================
REM Pinterest Auto Wallpaper PC Client - Build Script
REM Compiles the Python app into a single, windowless .exe using PyInstaller.
REM ============================================================================

echo.
echo ========================================
echo   Pinterest Auto Wallpaper Build Script
echo ========================================
echo.

REM Check if PyInstaller is installed
pip show pyinstaller >nul 2>&1
if errorlevel 1 (
    echo Installing PyInstaller...
    pip install pyinstaller
)

REM Clean previous build
if exist "dist" rmdir /s /q dist
if exist "build" rmdir /s /q build
if exist "WallpaperSync.spec" del WallpaperSync.spec
if exist "Pinterest Auto Wallpaper.spec" del "Pinterest Auto Wallpaper.spec"

echo Building "Pinterest Auto Wallpaper.exe"...
echo.

pyinstaller ^
    --onefile ^
    --noconsole ^
    --icon=icon.ico ^
    --name "Pinterest Auto Wallpaper" ^
    --add-data "config.py;." ^
    main.py

if errorlevel 1 (
    echo.
    echo [ERROR] Build failed!
    exit /b 1
)

echo.
echo ========================================
echo [OK] Build successful!
echo      Output: dist\Pinterest Auto Wallpaper.exe
echo ========================================
echo.
echo To run:
echo   dist\Pinterest Auto Wallpaper.exe              Interactive setup
echo   dist\Pinterest Auto Wallpaper.exe --sync       Silent wallpaper sync
echo   dist\Pinterest Auto Wallpaper.exe --install    Install daily task
echo   dist\Pinterest Auto Wallpaper.exe --uninstall  Remove daily task
echo.
