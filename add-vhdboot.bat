::run as admin
(Net session >nul 2>&1)&&(cd /d "%~dp0")||(PowerShell start """%~0""" -verb RunAs & Exit /B)

CD /D "%~dp0"

::dont use path variable!!
SET vhdpath=
SET /P vhdpath="vhd path?"

for /F "delims=" %%i in (%filepath%) do set filename="%%~nxi"

SET name=
SET /P name="entry name?"

if defined name goto exec



:exec
powershell.exe -NoProfile -ExecutionPolicy Unrestricted .\add-vhdboot.ps1 "%name%" "%vhdpath%"

:end
pause
