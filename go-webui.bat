set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
cd /d "%SCRIPT_DIR%"
set "PYTHON_DIR=%SCRIPT_DIR%\.venv\Scripts"
if not exist "%PYTHON_DIR%\python.exe" set "PYTHON_DIR=%SCRIPT_DIR%\runtime"
set "PATH=%PYTHON_DIR%;%SCRIPT_DIR%\runtime;%PATH%"
"%PYTHON_DIR%\python.exe" -I webui.py zh_CN
pause
