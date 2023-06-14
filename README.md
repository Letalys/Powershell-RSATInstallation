
# Powershell : RSAT Installation

This script can be use to install or Uninstall a set of RSAT Tools for Windows 10. You can use it standalone or integrate for SCCM/MECM deployment.

## How to use

### General

**You need to be administrator and have access to Internet (Microsoft).**

This script using JSON Input always stored in `/config` directory.
First you have ton configure a JSON file in Config Directory like Sample.

You can get the RSAT list from powershell with :
```
Get-WindowsCapability -Online | Where-Object {$_.Name -like "Rsat.*.tools*"} | Select-Object Name, State | ft
```

In JSON file, Only the name between RSAT and Tools is necessary.

`Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0` **>>** `ActiveDirectory.DS-LDS`

* If the state of an RSAT is declared to be install and is not, then install will proceed.
* If the State of an RSAT is declared to be not installed and is, then uninstall will proceed.

_Run script Command Line_ :
```
.\RSAT-Installation.ps1 -ConfigurationFileName "StoredJsonInConfigDir.json"
```

The Install log is currently stored in `c:\InstallRSAT.log`

### Windows Update Service

The script provide modifications for Windows Update service when starting and when ending.

This change is required for systems that have implemented an internal WSUS (or SCCM /MECM). The installation of the RSAT requires the cutting of this link. Once the installation is complete, it restores the WSUS link.

So you can remove this action as you want if you not need it.

## Links
https://github.com/Letalys/Powershell-RSATInstallation


## Autor
- [@Letalys (GitHUb)](https://www.github.com/Letalys)
