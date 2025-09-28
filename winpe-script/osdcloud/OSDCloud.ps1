#Requires -RunAsAdministrator
#Requires -Module OSD
#Requires -Module OSDCloud
<#
    .NOTES
    The initial PowerShell commands should always contain the -WindowStyle Hidden parameter to prevent the PowerShell window from appearing on the screen.
	powershell.exe -WindowStyle Hidden -Command {command}

	This will prevent PowerShell from rebooting since the window will not be visible.
	powershell.exe -WindowStyle Hidden -NoExit -Command {command}

	The final PowerShell command should contain the -NoExit parameter to keep the PowerShell window open and to prevent the WinPE environment from restarting.
	powershell.exe -WindowStyle Hidden -NoExit -Command {command}

	Wpeinit and Startnet.cmd: Using WinPE Startup Scripts
	https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/wpeinit-and-startnetcmd-using-winpe-startup-scripts?view=windows-11
#>
#=================================================
# Copy PowerShell Modules
# Make sure they are up to date on your device before running this script.
$ModuleNames = @('OSD', 'OSDCloud')
$ModuleNames | ForEach-Object {
	$ModuleName = $_
	Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Source)] Copy PowerShell Module to BootImage: $ModuleName"
	Copy-PSModuleToWindowsImage -Name $ModuleName -Path $MountPath | Out-Null
# As an alternative, you can use the following command to get the latest from PowerShell Gallery:
# Save-Module -Name $ModuleName -Path "$MountPath\Program Files\WindowsPowerShell\Modules" -Force
}
#=================================================
# Startnet.cmd
$Content = @'
@echo off
title OSDCloud WinPE Startup 25.9.24.1
wpeinit
wpeutil DisableFirewall
wpeutil UpdateBootInfo
powershell.exe -w h -c Invoke-OSDCloudPEStartup OSK
powershell.exe -w h -c Invoke-OSDCloudPEStartup DeviceHardware
powershell.exe -w h -c Invoke-OSDCloudPEStartup WiFi
powershell.exe -w h -c Invoke-OSDCloudPEStartup IPConfig
powershell.exe -w h -c Invoke-OSDCloudPEStartup UpdateModule -Value OSD
powershell.exe -w h -c Invoke-OSDCloudPEStartup UpdateModule -Value OSDCloud
powershell.exe -w h -c Invoke-OSDCloudPEStartup Info

# Modulpfad ermitteln
$moduleInfo = Get-Module -ListAvailable -Name OSDCloud | Sort-Object Version -Descending | Select-Object -First 1
$modulePath = $moduleInfo.ModuleBase
$workflowPath = Join-Path $modulePath 'workflow'

# Ordnerstruktur erstellen
$companyPath = Join-Path $workflowPath 'company'
$tasksPath   = Join-Path $companyPath 'tasks'
New-Item -Path $companyPath -ItemType Directory -Force | Out-Null
New-Item -Path $tasksPath   -ItemType Directory -Force | Out-Null

# Gist-URLs definieren
$gists = @{
    "os-amd64.json"   = "https://gist.githubusercontent.com/checkitsedo/3195abfe3eeab52ad23843a84e794f33/raw/spx-os-amd64.json"
    "os-arm64.json"   = "https://gist.githubusercontent.com/checkitsedo/5c948fdae5bc4634352438660d9d61d2/raw/spx-os-arm64.json"
    "user-amd64.json" = "https://gist.githubusercontent.com/checkitsedo/4cfd046b499e2166c5bd8ead0882ddc8/raw/spx-user-amd64.json"
    "user-arm64.json" = "https://gist.githubusercontent.com/checkitsedo/5e24f80033daca58ff90ebc834fdeafb/raw/spx-user-arm64.json"
    "osdcloud.json"   = "https://gist.githubusercontent.com/checkitsedo/c7d79a82a3a0bccec894a2102dc8ee8c/raw/spx-osdcloud.json"
}

# Dateien herunterladen
Invoke-WebRequest -Uri $gists["os-amd64.json"]   -OutFile (Join-Path $companyPath "os-amd64.json")
Invoke-WebRequest -Uri $gists["os-arm64.json"]   -OutFile (Join-Path $companyPath "os-arm64.json")
Invoke-WebRequest -Uri $gists["user-amd64.json"] -OutFile (Join-Path $companyPath "user-amd64.json")
Invoke-WebRequest -Uri $gists["user-arm64.json"] -OutFile (Join-Path $companyPath "user-arm64.json")
Invoke-WebRequest -Uri $gists["osdcloud.json"]   -OutFile (Join-Path $tasksPath   "osdcloud.json")

# start /wait PowerShell -NoL -C Start-OSDCloudWorkflow -CLI
wpeutil Reboot
pause
'@
Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Source)] Adding $MountPath\Windows\System32\startnet.cmd"
$Content | Out-File -FilePath "$MountPath\Windows\System32\startnet.cmd" -Encoding ascii -Width 2000 -Force
#=================================================