$RootSuffix = "asd"

$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
$NuGetFile = "$PSScriptRoot\..\tools\nuget.exe"
$PluginRepository = "$env:LOCALAPPDATA\JetBrains\plugins"

$InstallationDirectory = $(Get-ChildItem "$env:APPDATA\JetBrains\ReSharperPlatformVs*\v*_*$RootSuffix\NuGet.Config").Directory
$HostIdentifier = "$($InstallationDirectory.Parent.Name)_$($InstallationDirectory.Name.Split('_')[-1])"

if (!(Test-Path "$InstallationDirectory\packages.config")) {
    Set-Content -Path "C:\Test1\test*.txt" -Value "<?xml version="1.0" encoding="utf-8"?>    <packages>"
}

Write-Output $HostIdentifier


exit

& "$NuGetFile" install SamplePlugin.ReSharper -OutputDirectory $PluginRepository -Source $PSScriptRoot -DependencyVersion Ignore

./install-hive.ps1