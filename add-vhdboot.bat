::run as admin
(Net session >nul 2>&1)&&(cd /d "%~dp0")||(PowerShell start """%~0""" -verb RunAs & Exit /B)

CD /D "%~dp0"

::dont use path variable!!
SET vhdpath=
SET /P vhdpath="vhd path?"
SET name=
SET /P name="entry name?"

powershell.exe -NoProfile -ExecutionPolicy Unrestricted .\add-vhdboot.ps1 "%name%" "%vhdpath%"

timeout 10