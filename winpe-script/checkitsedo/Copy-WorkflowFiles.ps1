# Copy-WorkflowFiles.ps1
# Fügt den Unterordner 'company' rekursiv zur WinPE Umgebung hinzu.
# Verwende $MountPath als Ziel für die WinPE Umgebung.

param (
    [Parameter(Mandatory = $false)]
    [string]$SourceFolder = "$PSScriptRoot\company"
)

if (-not (Test-Path -Path $SourceFolder)) {
    Write-Error "Quellordner '$SourceFolder' existiert nicht."
    exit 1
}

if (-not (Test-Path -Path $MountPath)) {
    Write-Error "MountPath '$MountPath' ist nicht definiert oder existiert nicht."
    exit 1
}

$Destination = Join-Path -Path $MountPath -ChildPath "workflows"

Write-Host "Kopiere '$SourceFolder' nach '$Destination'..."

Copy-Item -Path $SourceFolder -Destination $Destination -Recurse -Force

Write-Host "Kopieren abgeschlossen."