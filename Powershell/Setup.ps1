#Require -RunAsAdministrator

# Script for initial setup of SBE devices
# @Author: Cody Bromwich
# Date: 11/13/2017

# TODO: Registry values for local group policy
#       Command to run ninite exe
#       Auto-create shortcuts for netsuite and outlook

# Start layout settings. Uses a predefined (in this case) bin file to set start layout for all users created after this script is run
function Set-StartLayout {
    $layout = $PSScriptRoot + "\layout.bin"
    $FileExist = Test-Path $layout

    if ($FileExist) {
        Import-StartLayout -LayoutPath $layout -MountPath "C:\"
    }
    else {
        [string]$ExportCurrentLayout = Read-Host "Layout file 'layout.bin' not found. Would you like to use the current layout? [Y/N]"

        if ($ExportCurrentLayout.ToLower() -eq "y") {
            Export-StartLayout -Path $layout
            Set-StartLayout
        }
        
    }
}

# Set default app associations from a predefined (in this case) xml file
function Set-AppAssociations {
    $AssociationsFile = $PSScriptRoot + "\MyDefaultAppAssociations.xml"
    $FileExist = Test-Path $AssociationsFile

    if ($FileExist) {
        dism /online /Import-DefaultAppAssociations:"$AssociationsFile" | Out-Null
        echo "`nSuccessfully imported App Associations"
    }
    else {
        [string]$ExportCurrentLayout = Read-Host "Layout file 'MyDefaultAppAssociations.xml' not found. Would you like to use the current layout? [Y/N]"

        if ($ExportCurrentLayout.ToLower() -eq "y") {
            dism /online /Export-DefaultAppAssociations:"$AssociationsFile" | Out-Null
            echo "`nSuccessfully exported App Associations`n"
            Set-AppAssociations
        }
        
    }
}

# Creates local user 
function Create-SBEUser {
    $AccountName = "Staybright Employee"
    New-LocalUser -Name $AccountName  -NoPassword # Create user with no password
    & NET LOCALGROUP Administrators $AccountName /add # Make user admin
}

# Run script as administrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit 
}

Set-StartLayout
Set-AppAssociations
cmd /c pause | Out-Null # Close output window on any key press