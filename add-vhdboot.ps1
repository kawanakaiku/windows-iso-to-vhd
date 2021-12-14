param ( $Menu, $Path )

if( $Menu -eq $null -or $Path -eq $null){
    Write-Output "Usage:"
    Write-Output " vhdboot.ps1 `"Boot menu`" VHD-FullPath"
    exit
}

if(Test-Path $Path){
    $Output = bcdedit /copy `{current`} /d "$Menu" | Out-String
    $Output = $Output -split " "
    $GUID = $Output[1]
    $Drive = Split-Path $Path -Qualifier
    $File = Split-Path $Path -noQualifier
    bcdedit /set $GUID device vhd=`[$Drive`]$File
    bcdedit /set $GUID osdevice vhd=`[$Drive`]$File
    bcdedit /set $GUID detecthal on
}
else{
    Write-Output "$Path not found"
}