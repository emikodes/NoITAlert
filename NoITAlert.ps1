$source = "https://dl.google.com/android/repository/platform-tools-latest-windows.zip"

$zip_file = Join-Path $PSScriptRoot "platform-tools.zip"
$extracted_path = Join-Path $PSScriptRoot "\platform-tools"

$adb = Join-Path $PSScriptRoot adb.exe

# download ADB
function download {
    # check if file is already downloaded
        if (-not($zip_file | Test-Path)){
            try{
                Write-Host "Downloading ADB"
                Start-BitsTransfer -Source $source -Destination $zip_file 
            }catch{
                Write-Host "Failed to download" -f red
                Write-Host $source -f red 
                Write-Warning $Error[0]
                Exit
            }
    }
}


function extract {
    Write-Host "Extracting zip file"
    Write-Host "========================================" -f blue
    try{
        Expand-Archive -LiteralPath $zip_file -DestinationPath $adb_path
    }catch{
        Write-Host "Failed to extract" -f red
        Write-Host $zip_file -f red
        Write-Warning $Error[0]
        Exit
    }
}

function cleanup {
    Write-Host "Cleanup"

    # search for adb files
    if ($extracted_path|Test-Path){
        $adb_files = Get-ChildItem -Path $extracted_path | Where{$_.Name -Match "adb"}
        # move them
        $adb_files.Foreach{
            Move-Item -Path $_.FullName -Destination $adb_path
        }
        # delete folder
        Remove-Item $extracted_path -Recurse
    }
    
    # delete zip
    Remove-Item $zip_file
}

#Start#
Write-Host "========================================" -f blue
Write-Host "
 _   _      _____ _____ ___  _           _   
| \ | |    |_   _|_   _/ _ \| |         | |  
|  \| | ___  | |   | |/ /_\ \ | ___ _ __| |_ 
| . ` |/ _ \ | |   | ||  _  | |/ _ \ '__| __|
| |\  | (_) || |_  | || | | | |  __/ |  | |_ 
\_| \_/\___/\___/  \_/\_| |_/_|\___|_|   \__|

Coded by @emikodes on GitHub."
Write-Host "========================================" -f blue


# check if adb is there
if ($adb | Test-Path){
    Write-Host "ADB already in directory"
    #kill-server in case adb is already running.
    &$adb kill-server
}else{
    download
    extract
    cleanup
}

$output = [string] (&$adb devices 2>&1)
Write-Host $output

if($output.Length -lt 103){ #length of "adb devices" return value, if no device is attached.
    Write-Host "Device not attached or USB debug not enabled."
    Write-host "Exiting..."
    EXIT
}else{
    #start removing packages...
    Write-Host "Removing ITAllert packages..."
    $output = [string] (&$adb shell pm uninstall -k --user 0 com.android.cellbroadcastreceiver 2>&1)
    Write-Host $output
    $output = [string] (&$adb shell pm uninstall -k --user 0 com.android.cellbroadcast 2>&1)
    Write-Host $output
    $output = [string] (&$adb shell pm uninstall -k --user 0 com.android.cellbroadcastreceiver.overlay.common 2>&1)
    Write-Host $output
    $output = [string] (&$adb shell pm uninstall -k --user 0 com.android.stk 2>&1)
    Write-Host $output
    $output = [string] (&$adb shell pm uninstall -k --user 0 com.android.stk2 2>&1)
    Write-Host $output
    $output = [string] (&$adb shell pm uninstall -k --user 0 com.android.cellbroadcastservice 2>&1)
    Write-Host $output

    &$adb kill-server
    Write-Host "DONE!"
}
