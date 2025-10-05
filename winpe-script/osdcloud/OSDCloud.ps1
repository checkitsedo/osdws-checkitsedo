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

powershell.exe -w h -c Invoke-WebPSScript https://gist.githubusercontent.com/checkitsedo/8ef578c9165d78d73ec2005afe74cceb/raw/spx_osdcloud_Prepare-OSDCloudWorkflow.ps1 -Wait

powershell.exe -w h -c Invoke-OSDCloudPEStartupCommand Use-PEStartupDeviceInfo -NoExit
powershell.exe -w h -c Invoke-WebPSScript https://gist.githubusercontent.com/checkitsedo/b9e272636a73a1c14aede5c47639ae97/raw/spx_osdcloud_bootstrap.ps1

wpeutil Reboot
pause
'@
Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Source)] Adding $MountPath\Windows\System32\startnet.cmd"
$Content | Out-File -FilePath "$MountPath\Windows\System32\startnet.cmd" -Encoding ascii -Width 2000 -Force
#=================================================