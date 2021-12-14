@echo off
setlocal
set "err="


::exit if w, s drive letter in use

if exist "w:\" (
   set "err=letter w in use"
   goto e
) else if exist "s:\" (
   set "err=letter s in use"
   goto e
)


::::run as admin

(Net session >nul 2>&1)&&(cd /d "%~dp0")||(PowerShell start """%~0""" -verb RunAs & Exit /B)


::::cd to same dir

CD /D "%~dp0"


::::set files and options

set "isofile="D:\Downloads\iso\Win11_Japanese_x64v1.iso""
set "driverdir=G:\drivers"
set "vhdfile=D:\win10-1507.vhdx"
set "uefi=true"
::uncomment to make for bios
::set "uefi="

if defined uefi (
   echo ::making for uefi
) else (
   echo ::making for bios
)

::exit if given file and folder not found or vhd already exists

if not exist "%isofile%" (
   set "err=%isofile% not found"
   goto e
) else if not exist "%driverdir%" (
   set "err=%driverdir% not found"
   goto e
) else if exist "%vhdfile%" (
   set "err=%vhdfile% already exists"
   goto e
)


::::format vhd(x)
echo ::creating and formatting a vhd

(

   echo create vdisk file="%vhdfile%" maximum=80000 type=expandable
   echo select vdisk file="%vhdfile%"
   echo attach vdisk
   echo clean

   if defined uefi (
      echo convert gpt
      echo create partition efi size=100
      echo format quick fs=fat32 label="System"
   ) else (
      echo convert mbr
      echo create partition primary size=500
      echo format quick fs=ntfs label="System"
      echo active
   )

   echo assign letter="s"
   echo create partition primary
   echo format quick fs=ntfs label="Windows"
   echo assign letter="w"

) | C:\Windows\System32\diskpart.exe


::exit if vhd creation failed

if not exist "%vhdfile%" (
   set "err=creating vhd failed"
   goto e
)
if not exist "w:\" (
   set "err=formatting vhd failed"
   goto e
)
if not exist "s:\" (
   set "err=formatting vhd failed"
   goto e
)

echo ##created and formatted vhd successfully


::::apply image

::mount iso and get its letter
set ps_command=`powershell "(Mount-DiskImage "%isofile%" | Get-Volume).DriveLetter"`
FOR /F "usebackq delims=" %%A IN (%ps_command%) DO set driveletter=%%A

::exit if installation archive not exists

if exist "%driveletter%:\sources\install.wim" (
    set "INSTALL=%driveletter%:\sources\install.wim"
) else if exist "%driveletter%:\sources\install.esd" (
    set "INSTALL=%driveletter%:\sources\install.esd"
) else (
    set "err=%isofile% may not be a instllation iso"
    goto e
)

::apply

C:\Windows\System32\Dism.exe /Apply-Image /ImageFile:%INSTALL% /index:0 /ApplyDir:W:\ || ( set "err=applying image failed" )

::unmount iso
echo ::unmounting iso
powershell "Dismount-DiskImage -ImagePath "%isofile%"" >NUL

::exit for former error

if defined err (
   goto d
)

echo ##successfully applied image to the vhd

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
echo ::injecting drivers
C:\Windows\System32\Dism.exe /Image:W:\ /Add-Driver /Driver:"%driverdir%" /Recurse


::::reduce size
::comment if error occurs
call make-vhd-reduce.bat


::::detach vhd(x)
:d
echo ::detaching vhd
(
   echo select vdisk file="%vhdfile%"
   echo detach vdisk
) | C:\Windows\System32\diskpart.exe


goto exit
::abnormal terminate
:e
echo !!%err%


:exit
echo !!Exitting
endlocal
pause
