@echo off
setlocal
set "err="

::::cd to same dir

CD /D "%~dp0"


::exit if w, s drive letter in use

if exist "w:\" (
   set "err=letter w in use"
   goto e
) else if exist "s:\" (
   set "err=letter s in use"
   goto e
)

::::set files and options

set "isofile=D:\Downloads\iso\Win11_Japanese_x64v1.iso"
set "driverdir=D:\drivers"
set "vhdfile=R:\win11-v1.vhdx"
set "uefi=true"

::uncomment to make for bios
::set "uefi="

::uncomment not to inject drivers
::set "drivers="

if defined uefi (
   echo ::making for uefi
) else (
   echo ::making for bios
)

::exit if given file and folder not found or vhd already exists

if not exist "%isofile%" (
   set "err=%isofile% not found"
   goto e
) else if defined drivers if not exist "%driverdir%" (
   set "err=%driverdir% not found"
   goto e
) else if exist "%vhdfile%" (
   set "err=%vhdfile% already exists"
   goto e
)

::::run as admin

(Net session >nul 2>&1)&&(cd /d "%~dp0")||(PowerShell start """%~0""" -verb RunAs & Exit /B)


::::mount iso and get its letter
echo ::mounting the iso
set ps_command=`powershell "(Mount-DiskImage "%isofile%" | Get-Volume).DriveLetter"`
FOR /F "usebackq delims=" %%A IN (%ps_command%) DO set driveletter=%%A

::exit if installation archive not exists

if exist "%driveletter%:\sources\install.wim" (
    set "INSTALL=%driveletter%:\sources\install.wim"
) else if exist "%driveletter%:\sources\install.esd" (
    set "INSTALL=%driveletter%:\sources\install.esd"
) else (
    set "err=%isofile% may not be a instllation iso"
    goto u
)


::::format vhd(x)
echo ::creating and formatting a vhd

if defined uefi (
   set "d1=convert gpt"
   set "d2=create partition efi size=100"
   set "d3=format quick fs=fat32 label="System""
   set "d4=rem"
) else (
   set "d1=convert mbr"
   set "d2=create partition primary size=500"
   set "d3=format quick fs=ntfs label="System""
   set "d4=active"
)

(
   echo create vdisk file="%vhdfile%" maximum=80000 type=expandable
   echo select vdisk file="%vhdfile%"
   echo attach vdisk
   echo clean
   echo %d1%
   echo %d2%
   echo %d3%
   echo %d4%
   echo assign letter="s"
   echo create partition primary
   echo format quick fs=ntfs label="Windows"
   echo assign letter="w"
) | C:\Windows\System32\diskpart.exe >NUL


::exit if vhd creation failed

if not exist "%vhdfile%" (
   set "err=creating vhd failed"
   goto u
)
if not exist "w:\" (
   set "err=formatting vhd failed (w:\ not exists)"
   goto u
)

echo ##created and formatted vhd successfully


::::apply image

::apply
echo ::applying image to vhd
echo ::using %INSTALL%
C:\Windows\System32\Dism.exe /Apply-Image /ImageFile:"%INSTALL%" /index:1 /ApplyDir:W:\ || ( set "err=applying image failed" )

::unmount iso
:u
echo ::unmounting iso
powershell "Dismount-DiskImage -ImagePath "%isofile%"" >NUL

::exit for former error

if defined err (
   goto d
)

echo ##successfully applied image to the vhd

:prevent VHD_BOOT_HOST_VOLUME_NOT_ENOUGH_SPACE
reg load HKLM\regtemp W:\Windows\System32\config\SYSTEM
reg add "HKLM\regtemp\ControlSet001\Services\FsDepends\Parameters" /f /v VirtualDiskExpandOnMount /t REG_DWORD /d 4
reg unload HKLM\regtemp

::set keyboard layout
::6 for jp
echo ::setting keyboard layout
C:\Windows\System32\Dism.exe /Image:W:\ /Set-LayeredDriver:6

::make vhd bootable
echo ::making the vhd bootable
if defined uefi (
   C:\Windows\System32\bcdboot.exe W:\Windows /l ja-jp /s S: /f UEFI
) else (
   C:\Windows\System32\bcdboot.exe W:\Windows /l ja-jp /s S: /f BIOS
)

::inject drivers
if defined drivers (
   echo ::injecting drivers
   C:\Windows\System32\Dism.exe /Image:W:\ /Add-Driver /Driver:"%driverdir%" /Recurse
)


::::reduce size
::comment if error occurs
call make-vhd-reduce.bat


::::detach vhd(x)
:d
if not exist "%vhdfile%" goto dskip
echo ::detaching vhd
(
   echo select vdisk file="%vhdfile%"
   echo detach vdisk
) | C:\Windows\System32\diskpart.exe >NUL
:dskip
if defined err ( goto e ) else ( goto exit )

::abnormal terminate
:e
echo !!%err%


:exit
if defined err (
   echo !!Exitting
) else (
   echo ::Exitting
)
endlocal
pause
