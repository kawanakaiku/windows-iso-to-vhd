@echo off
setlocal enabledelayedexpansion


set CSV_file=make-vhd-reduce.csv
set Array_Index=0

::read list from csv

FOR /F "delims=" %%I IN (%CSV_file%) DO (
    SET "Arr[!Array_Index!]=%%I"
    SET /a Array_Index=!Array_Index!+1
)


set I=0
:loop
call set F=%%Arr[%I%]%%
set /a I=%I% + 1

if not defined F ( goto end )

if not ["%F%"] == [""] (
    if exist "%F%" (
        echo ::trying to delete "%F%"
        takeown /F "%F%" /R /A >NUL 2>&1 || takeown /F "%F%" /A >NUL 2>&1
        icacls "%F%" /T /grant Administrators:F >NUL 2>&1
        rmdir /s /q "%F%" >NUL 2>&1 || del /f "%F%" >NUL 2>&1
    )
    goto loop
)

:end
endlocal
