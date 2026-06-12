@echo off
setlocal EnableDelayedExpansion

title Muffin CLI Windows Installer

:: Check for Administrative privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :admin_verified
) else (
    echo ====================================================
    echo         Requesting Administrative Privileges...
    echo ====================================================
    :: Spawns elevated wrapper using PowerShell
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:admin_verified
:: Restore current directory since running as Admin resets it to System32
cd /d "%~dp0"

echo ====================================================
echo         Muffin Windows CLI Installer Engine         
echo ====================================================
echo.

:: 1. Verify basic dependency (Python is required for Muffin's Webview Engine)
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python was not found in your system PATH.
    echo Muffin requires Python 3+ to drive the Microsoft Edge WebView2 engine.
    echo Please install Python (and check the 'Add Python to PATH' option) and try again.
    echo.
    pause
    exit /b 1
)

:: 2. Set Up Target Installation Path
set "INSTALL_DIR=C:\Program Files\Muffin"
set "TARGET_FILE=%INSTALL_DIR%\muffin.bat"

if not exist "%INSTALL_DIR%" (
    echo Creating installation folder at: %INSTALL_DIR%...
    mkdir "%INSTALL_DIR%"
)

:: 3. Download muffin.bat from GitHub (windows branch)
set "DOWNLOAD_URL=https://raw.githubusercontent.com/AstroMeYT/muffin/refs/heads/windows/muffin.bat"
echo Downloading muffin.bat from GitHub...

powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%TARGET_FILE%'"
if %errorlevel% neq 0 (
    echo [ERROR] Failed to download muffin.bat. Please check your internet connection.
    pause
    exit /b 1
)
echo [SUCCESS] muffin.bat downloaded.

:: 4. Add installation folder to the system PATH environment variable safely
echo Registering Muffin into System PATH...

:: PowerShell handles environment variables safely without 1024-char limit truncations
powershell -Command ^
    "$currentPath = [Environment]::GetEnvironmentVariable('Path', 'Machine'); " ^
    "if ($currentPath -split ';' -notcontains '%INSTALL_DIR%') { " ^
    "    [Environment]::SetEnvironmentVariable('Path', $currentPath + ';%INSTALL_DIR%', 'Machine'); " ^
    "    write-host '[SUCCESS] Added to System PATH.' -ForegroundColor Green " ^
    "} else { " ^
    "    write-host '[INFO] Already registered in PATH.' -ForegroundColor Yellow " ^
    "}"

:: 5. Run Muffin once to trigger its automatic registry setup for .mpa associations
echo.
echo Initializing Muffin and registering system file associations...
call "%TARGET_FILE%" >nul 2>&1

echo.
echo ====================================================
echo        Muffin Successfully Installed!
echo ====================================================
echo.
echo You can now use 'muffin' directly in any NEW CMD,
echo PowerShell, or Terminal window.
echo.
echo Quick CLI Commands:
echo   muffin run ^<path_to_app.mpa^>
echo   muffin delete ^<app_name^>
echo.
echo Double-clicking '.mpa' files will now launch them!
echo ====================================================
pause
exit /b