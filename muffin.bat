@echo off
setlocal EnableDelayedExpansion

:: Muffin - Portable Web App Runner (Windows Edition)
:: Usage:
::   muffin run <path\to\app.mpa_or_app_name>
::   muffin delete <path\to\app.mpa_or_app_name>

set "MUFFIN_DIR=%LOCALAPPDATA%\muffin"
set "MUFFIN_LIB=%MUFFIN_DIR%\library"
set "MUFFIN_APPS=%MUFFIN_DIR%\apps"
set "MUFFIN_DATA=%MUFFIN_DIR%\data"
set "PYTHON_RUNNER=%MUFFIN_DIR%\runner.py"

:: 1. Ensure target directories exist
if not exist "%MUFFIN_LIB%" mkdir "%MUFFIN_LIB%"
if not exist "%MUFFIN_APPS%" mkdir "%MUFFIN_APPS%"
if not exist "%MUFFIN_DATA%" mkdir "%MUFFIN_DATA%"

:: 2. Setup user file associations for double-clicking .mpa archives
call :ensure_associations

:: 3. Verify dependencies (Python is required for Windows Webview2 bridge)
python --version >nul 2>&1
if errorlevel 1 (
    echo Error: Python is not installed or not added to PATH.
    echo Please install Python from the Microsoft Store or python.org to use Muffin.
    pause
    exit /b 1
)

:: Verify arguments
if "%~1"=="" goto usage
if "%~2"=="" goto usage

set "COMMAND=%~1"
set "INPUT_ARG=%~2"

:: Extract clean application name
for %%I in ("%INPUT_ARG%") do set "APP_NAME=%%~nI"

if /I "%COMMAND%"=="delete" goto delete_app
if /I "%COMMAND%"=="run" goto run_app

:usage
echo Muffin Portable Archive Launcher (Windows)
echo Usage:
echo   muffin run ^<path\to\app.mpa_or_app_name^>
echo   muffin delete ^<path\to\app.mpa_or_app_name^>
exit /b 1

:: --- REGISTRY FILE ASSOCIATION ROUTINE (NO ADMIN REQUIRED) ---
:ensure_associations
reg query "HKCU\Software\Classes\Muffin.Assoc\shell\open\command" /ve 2>nul | findstr /i "%~f0" >nul
if %errorlevel% neq 0 (
    echo Configuring .mpa Windows system file associations...
    
    :: Bind extension to user-level class
    reg add "HKCU\Software\Classes\.mpa" /ve /t REG_SZ /d "Muffin.Assoc" /f >nul 2>&1
    reg add "HKCU\Software\Classes\.mpa" /v "Content Type" /t REG_SZ /d "application/x-muffin-portable-archive" /f >nul 2>&1
    
    :: Set Friendly Display name for the file type
    reg add "HKCU\Software\Classes\Muffin.Assoc" /ve /t REG_SZ /d "Muffin Portable Archive" /f >nul 2>&1
    
    :: Assign a beautiful system globe icon for .mpa files
    reg add "HKCU\Software\Classes\Muffin.Assoc\DefaultIcon" /ve /t REG_EXPAND_SZ /d "shell32.dll,14" /f >nul 2>&1
    
    :: Configure open action command pointing back to current muffin.bat script location
    reg add "HKCU\Software\Classes\Muffin.Assoc\shell\open\command" /ve /t REG_EXPAND_SZ /d "cmd.exe /c \"\"%~f0\" run \"%%1\"\"" /f >nul 2>&1
    
    :: Force Windows Explorer to refresh its icon cache immediately
    ie4uinit.exe -show >nul 2>&1
    echo File associations registered successfully! Double-click any .mpa file to launch.
)
exit /b 0

:: --- DELETE COMMAND LOGIC ---
:delete_app
echo Uninstalling Muffin App: %APP_NAME%

set "DELETED_ANY=false"

if exist "%MUFFIN_APPS%\%APP_NAME%" (
    rd /s /q "%MUFFIN_APPS%\%APP_NAME%"
    echo   - Cleaned extracted application files.
    set "DELETED_ANY=true"
)
if exist "%MUFFIN_DATA%\%APP_NAME%" (
    rd /s /q "%MUFFIN_DATA%\%APP_NAME%"
    echo   - Cleaned persistent session data.
    set "DELETED_ANY=true"
)
if exist "%MUFFIN_LIB%\%APP_NAME%.mpa" (
    del /q "%MUFFIN_LIB%\%APP_NAME%.mpa"
    echo   - Deleted package from Muffin library.
    set "DELETED_ANY=true"
)
set "SHORTCUT_PATH=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Muffin\%APP_NAME%.lnk"
if exist "%SHORTCUT_PATH%" (
    del /q "%SHORTCUT_PATH%"
    echo   - Removed Start Menu shortcut.
    set "DELETED_ANY=true"
)

if "%DELETED_ANY%"=="true" (
    echo Successfully deleted '%APP_NAME%'.
) else (
    echo No installed components found for app '%APP_NAME%'.
)
exit /b 0


:: --- RUN COMMAND LOGIC ---
:run_app
set "MPA_FILE="
if exist "%INPUT_ARG%" set "MPA_FILE=%INPUT_ARG%"
if exist "%MUFFIN_LIB%\%INPUT_ARG%" set "MPA_FILE=%MUFFIN_LIB%\%INPUT_ARG%"
if exist "%MUFFIN_LIB%\%INPUT_ARG%.mpa" set "MPA_FILE=%MUFFIN_LIB%\%INPUT_ARG%.mpa"

if "%MPA_FILE%"=="" (
    echo Error: Could not find application '%INPUT_ARG%' locally or in your library.
    exit /b 1
)

:: Resolve to absolute file path
for %%I in ("%MPA_FILE%") do set "MPA_FILE=%%~fI"
set "APP_DIR=%MUFFIN_APPS%\%APP_NAME%"
set "APP_DATA_DIR=%MUFFIN_DATA%\%APP_NAME%"

if not exist "%APP_DATA_DIR%" mkdir "%APP_DATA_DIR%"

echo Loading %APP_NAME%...
if exist "%APP_DIR%" rd /s /q "%APP_DIR%"
mkdir "%APP_DIR%"

:: Extract the archive using Windows 10+ native tar
tar -xf "%MPA_FILE%" -C "%APP_DIR%" >nul 2>&1
if errorlevel 1 (
    echo Falling back to PowerShell extraction...
    powershell -NoProfile -Command "Expand-Archive -Force -Path '%MPA_FILE%' -DestinationPath '%APP_DIR%'"
)

:: Route Target URL (Live App vs Local App)
set "TARGET_URL="
if exist "%APP_DIR%\live.txt" (
    set /p TARGET_URL=<"%APP_DIR%\live.txt"
    echo Live App Detected: Routing to !TARGET_URL!
) else (
    set "INDEX_PATH="
    for /r "%APP_DIR%" %%F in (index.html) do (
        if "!INDEX_PATH!"=="" set "INDEX_PATH=%%F"
    )
    if "!INDEX_PATH!"=="" (
        echo Error: Invalid Muffin App: Missing live.txt or index.html in the archive.
        exit /b 1
    )
    :: Convert Windows path slashes to forward slashes for file:// URI
    set "FORMATTED_PATH=!INDEX_PATH:\=/!"
    set "TARGET_URL=file:///!FORMATTED_PATH!"
)

:: Start Menu Shortcut Generation
set "SHORTCUT_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Muffin"
if not exist "%SHORTCUT_DIR%" mkdir "%SHORTCUT_DIR%"
set "SHORTCUT_PATH=%SHORTCUT_DIR%\%APP_NAME%.lnk"

if not exist "%SHORTCUT_PATH%" (
    echo Adding %APP_NAME% to Start Menu...
    set "VBS_SCRIPT=%MUFFIN_DIR%\createshortcut.vbs"
    (
        echo Set oWS = WScript.CreateObject^("WScript.Shell"^)
        echo sLinkFile = "%SHORTCUT_PATH%"
        echo Set oLink = oWS.CreateShortcut^(sLinkFile^)
        echo oLink.TargetPath = "%~f0"
        echo oLink.Arguments = "run """%MPA_FILE%""""
        echo oLink.Description = "Muffin Portable App"
        echo oLink.WindowStyle = 1
        echo oLink.Save
    ) > "!VBS_SCRIPT!"
    cscript //nologo "!VBS_SCRIPT!"
    del "!VBS_SCRIPT!"
)

:: Create Python WebView Runner (Using PyWebView + Windows Edge Chromium)
(
echo import sys
echo import os
echo import subprocess
echo try:
echo     import webview
echo except ImportError:
echo     print^("First-time setup: Installing WebView2 bindings for Windows..."^)
echo     subprocess.check_call^[^[sys.executable, "-m", "pip", "install", "pywebview"^]^]
echo     import webview
echo app_title = sys.argv^[1^]
echo app_url = sys.argv^[2^]
echo data_dir = sys.argv^[3^]
echo # Force Edge Chromium to isolate session profiles
echo os.environ^["WEBVIEW2_USER_DATA_FOLDER"^] = data_dir
echo window = webview.create_window^(app_title, app_url, width=1280, height=800^)
echo webview.start^(private_mode=False^)
) > "%PYTHON_RUNNER%"

echo Launching %APP_NAME%...
python "%PYTHON_RUNNER%" "%APP_NAME%" "%TARGET_URL%" "%APP_DATA_DIR%"