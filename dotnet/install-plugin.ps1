$RootSuffix = "asd"
$PluginId = "SamplePlugin.ReSharper"

$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
$OutputDirectory = "$PSScriptRoot\output"
$NuGetFile = "$PSScriptRoot\..\tools\nuget.exe"
$PluginRepository = "$env:LOCALAPPDATA\JetBrains\plugins"
$InstallationDirectory = $(Get-ChildItem "$env:APPDATA\JetBrains\ReSharperPlatformVs*\v*_*$RootSuffix\NuGet.Config").Directory

# Adapt packages.config
if (Test-Path "$InstallationDirectory\packages.config") {
    $PackagesXml = [xml] (Get-Content "$InstallationDirectory\packages.config")
} else {
    $PackagesXml = [xml] ("<?xml version=`"1.0`" encoding=`"utf-8`"?><packages></packages>")
}

if ($null -eq $PackagesXml.SelectSingleNode(".//package[@id='$PluginId']/@id")) {
    $PluginNode = $PackagesXml.CreateElement('package')
    $PluginNode.setAttribute("id", "$PluginId")
    $PluginNode.setAttribute("version", "$Version")

    $PackagesNode = $PackagesXml.SelectSingleNode("//packages")
    $PackagesNode.AppendChild($PluginNode)

    $PackagesXml.Save("$InstallationDirectory\packages.config")
}

# Adapt project file
$HostIdentifier = "$($InstallationDirectory.Parent.Name)_$($InstallationDirectory.Name.Split('_')[-1])"
$ProjectXmlFile = "$PSScriptRoot\src\SamplePlugin.ReSharper\SamplePlugin.ReSharper.csproj.user"

$ProjectXml = [xml] (Get-Content "$ProjectXmlFile")
$HostIdentifierNode = $ProjectXml.SelectSingleNode(".//HostFullIdentifier")
$HostIdentifierNode.InnerText = $HostIdentifier
$ProjectXml.Save("$ProjectXmlFile")

# Install plugin
& dotnet pack SamplePlugin.sln --output "$OutputDirectory"
& "$NuGetFile" install SamplePlugin.ReSharper -OutputDirectory "$PluginRepository" -Source "$OutputDirectory" -DependencyVersion Ignore
# ./install-hive.ps1