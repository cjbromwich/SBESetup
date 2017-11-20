#Require -RunAsAdministrator

# Script for initial setup of SBE devices
# @Author: Cody Bromwich
# Date: 11/13/2017

# TODO: Registry values for local group policy (?)
#       Auto-create shortcuts for netsuite and outlook
#       Taskbar: Pin Chrome, unpin everything else

# Start layout settings. Uses a predefined (in this case) bin file to set start layout for all users created after this script is run
function Set-StartLayout {
    $layout = $PSScriptRoot + "\layout.xml" # Sets the layout master file to current directory\layout.bin. If this file does not exist, it is created in this function
    $FileExist = Test-Path $layout

    if ($FileExist) {
        echo "Importing start layout`n"
        Import-StartLayout -LayoutPath $layout -MountPath "C:\"
    }
    else {
        [string]$ExportCurrentLayout = Read-Host "Layout file 'layout.xml' not found. Would you like to use the current layout? [Y/N]"
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
        echo "Importing App Associations`n"
    }
    else {
        [string]$ExportCurrentLayout = Read-Host "Layout file 'MyDefaultAppAssociations.xml' not found. Would you like to use the current layout? [Y/N]"
        if ($ExportCurrentLayout.ToLower() -eq "y") {
            dism /online /Export-DefaultAppAssociations:"$AssociationsFile" | Out-Null
            echo "Successfully exported App Associations`n"
            Set-AppAssociations
        }
    }
}

# Creates local users - SBE Admin and Staybright Employee
function Create-Users {
    $AccountName = "Staybright Employee"
    $AdminAccount = "SBE Admin"

    echo "Creating users`n"

    New-LocalUser -Name $AccountName  -NoPassword # Create user with no password
    & NET LOCALGROUP Administrators $AccountName /add # Make user admin

    New-LocalUser -Name $AdminAccount -Password "T3chn0Log!c"
    & NET LOCALGROUP Administrators $AdminAccount /add # Make user admin
}

# Removes the account used to run this script. Most of the functions here will only work on accounts created after they are ran. Account will be gone after reboot
function Remove-SetupAccount {
  $CurrentUser = $env:UserName
  Remove-LocalUser -Name $CurrentUser
  echo "Removed current user. Current user will disappear after reboot`n"
}

# Run Ninite exe
function Run-Ninite {
  $path = $PSScriptRoot + "\ninite.exe"
  $FileExist = Test-Path $path

  if ($FileExist) {
    echo "Running Ninite`n"
    & $path
  }
  else {
    echo "Ninite not found. Please download and run manually`n"
  }
}

# Disables Cortana for all users and restarts explorer
function Disable-Cortana {
  $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
  if (!Test-Path -Path $path) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -Name "Windows Search"
  }
  echo "Disabling Cortana`n"
  Set-ItemProperty -Path $path -Name "AllowCortana" -Value 0
  Stop-Process -name explorer
}

# Installs Adobe Reader using offline installer
function Install-Adobe {
  $path = "\AdbeRdr11010_en_US.exe"
  if (Test-Path -Path $path) {
    echo "Installing Adobe Reader`n"
    & $path /msi EULA_ACCEPT=YES /qn
  }
  else {
    echo "Adobe installer not found, please download manually`n"
  }
}

# Run script as administrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

Run-Ninite
Set-StartLayout
Set-AppAssociations
Disable-Cortana
Install-Adobe
Create-Users
Remove-SetupAccount


cmd /c pause | Out-Null # Keep output window open until key is pressed
