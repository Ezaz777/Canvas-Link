@echo off
REM ============================================================================
REM WallpaperSync PC Client — Build Script
REM Compiles the Python app into a single, windowless .exe using PyInstaller.
REM ============================================================================

echo.
echo ========================================
echo   WallpaperSync Build Script
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

echo Building WallpaperSync.exe...
echo.

pyinstaller ^
    --onefile ^
    --noconsole ^
    --icon=icon.ico ^
    --name WallpaperSync ^
    --add-data "config.py;." ^
    main.py

if errorlevel 1 (
    echo.
    echo ❌ Build failed!
    exit /b 1
)

echo.
echo ========================================
echo ✅ Build successful!
echo    Output: dist\WallpaperSync.exe
echo ========================================
echo.
echo To run:
echo   dist\WallpaperSync.exe              Interactive setup
echo   dist\WallpaperSync.exe --sync       Silent wallpaper sync
echo   dist\WallpaperSync.exe --install    Install daily task
echo   dist\WallpaperSync.exe --uninstall  Remove daily task
echo.

