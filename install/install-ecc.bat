@echo off
REM CCPM-ECC Installer for Windows
REM Installs CCPM (trimmed for Everything Claude Code compatibility) into the current project.
REM Prerequisites: Everything Claude Code plugin must be installed globally.
REM
REM Usage: Run from your project root in Git Bash:
REM   bash install/install-ecc.sh
REM
REM Or use this bat file which delegates to Git Bash:

where bash >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Git Bash not found. Install Git for Windows first.
    exit /b 1
)

bash "%~dp0install-ecc.sh"
