<#
.SYNOPSIS
  Install RSAT Tools For Windows 10
.DESCRIPTION
  Install an RSAT list from JSON Configuration file
.INPUT
  Path to JSON Configuration File
.NOTES
  Version:        1.0
  Author:         Letalys
  Creation Date:  14/06/2023
  Purpose/Change: Initial script development

.LINK
    Author : Letalys (https://github.com/Letalys)
#>

param
	(
		[ValidateNotNullOrEmpty()][Parameter(Mandatory=$true)][string]$ConfigurationFileName
	)

Clear-Host

function Get-LogDate {
    return "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)  
} 


$ErrorActionPreference = "SilentlyContinue"

$LogFilePath = "C:\InstallRSAT.log"
$WSUSReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
$WSUSProp = "UseWUServer"

Try{
    $CurrentFolder = Split-Path $MyInvocation.MyCommand.Path
    $CurrentConfiguration = "$($CurrentFolder)\Config\$($ConfigurationFileName)"

    Remove-Item -Path $LogFilePath -Force -ErrorAction SilentlyContinue

    #Recreate LogFile
    If(!(Test-Path $LogFilePath)){
        New-Item $LogFilePath -force -type file | Out-Null
    }

    Add-Content $LogFilePath  "$(Get-LogDate) - Configure RSAT From <$($CurrentConfiguration)>"

    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
        Add-Content $LogFilePath  "$(Get-LogDate) - You need to be administrator to run this script."
        Write-host -ForegroundColor red "You need to be administrator to run this script."
        Exit
    }
    
    Add-Content $LogFilePath  "$(Get-LogDate) - Change WSUS Link from registry to set it online"
    Set-Itemproperty -path "$WSUSReg" -Name "$WSUSProp" -value 0

    Add-Content $LogFilePath  "$(Get-LogDate) - Restart Windows Update Service"
    Restart-Service -Name "wuauserv" -Force
    Start-Sleep -Seconds 5

    $JSON =  Get-Content -Raw -Path $CurrentConfiguration  | ConvertFrom-Json  
    
    Foreach($RSAT in $JSON.rsat_features.feature){
        Try{
            Add-Content $LogFilePath  "$(Get-LogDate) - $($RSAT.name) must be installed : $($RSAT.Install)"
            $CurrentRSAT = Get-WindowsCapability -Online | Where-Object {$_.Name -like "Rsat.$($RSAT.name).Tools*"}

            if(($CurrentRSAT.State -eq "Installed") -and ($RSAT.Install -eq $true)){
                Add-Content $LogFilePath  "$(Get-LogDate) - $($RSAT.name) already installed"
            }

            if(($CurrentRSAT.State -eq "NotPresent") -and ($RSAT.Install -eq $true)){
                Add-Content $LogFilePath  "$(Get-LogDate) - $($RSAT.name) must be install"
                Add-WindowsCapability -Online -Name $CurrentRSAT.Name | Out-Null
                Add-Content $LogFilePath  "$(Get-LogDate) - $($RSAT.name) have been installed"
            }

            if(($CurrentRSAT.State -eq "NotPresent") -and ($RSAT.Install -eq $false)){
                Add-Content $LogFilePath  "$(Get-LogDate) - $($RSAT.name) already NotPresent"
            }

            if(($CurrentRSAT.State -eq "Installed") -and ($RSAT.Install -eq $false)){
                Add-Content $LogFilePath  "$(Get-LogDate) - $($RSAT.name) must be uninstall"
                Remove-WindowsCapability -Name $CurrentRSAT.Name -Online | Out-Null
                Add-Content $LogFilePath  "$(Get-LogDate) - $($RSAT.name) have been removed"
            }
        }Catch{
             Add-Content $LogFilePath  "$(Get-LogDate) - ERROR : $($_)"
        }
    }
}Catch{
    Add-Content $LogFilePath  "$(Get-LogDate) - ERROR : $($_)"
}Finally{
    Add-Content $LogFilePath  "$(Get-LogDate) - Change WSUS Link from registry to set it offline"
    Set-Itemproperty -path "$WSUSReg" -Name "$WSUSProp" -value 1

    Add-Content $LogFilePath  "$(Get-LogDate) - Restart Windows Update Service"
    Restart-Service -Name "wuauserv" -Force

    Add-Content $LogFilePath  "$(Get-LogDate) - Ending install RSAT for Windows 10."
}
